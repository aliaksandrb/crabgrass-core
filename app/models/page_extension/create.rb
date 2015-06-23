module PageExtension::Create
  def self.included(base)
    base.extend(ClassMethods)
    #base.instance_eval do
    #  include InstanceMethods
    #end
  end

  #
  # special magic page create
  #
  # just like a normal activerecord.create, but with some magic options that
  # may optionally be passed in as attributes:
  #
  #  :user -- the user creating the page. they become the creator and owner
  #           of the page.
  #  :share_with -- other people, groups, or emails to share this page with.
  #  :access -- what access to grant them (defaults to :admin)
  #  :inbox -- send page to inbox?
  #
  # There are two versions create!() and create(). Both might throw exceptions
  # caused by bad sharing, but the first one will also throw exceptions if the
  # attributes don't validate.
  #
  module ClassMethods
    def create!(attributes = {}, &block)
      page = build!(attributes, &block)
      page.save!
      page
    end

    def create(attributes={}, &block)
      begin
        create!(attributes, &block)
      rescue ActiveRecord::RecordInvalid => exc
        exc.record
      end
    end

    #
    # build a page in memory, but don't save anything.
    #
    def build!(attributes={}, &block)
      if attributes.is_a?(Array)
        # act like normal create
        super(attributes, &block)
      else
        # extract extra attributes
        attributes = attributes.dup
        user       = attributes.delete(:user)
        owner      = attributes.delete(:owner)
        recipients = attributes.delete(:share_with)
        inbox      = attributes.delete(:inbox)
        access     = (attributes.delete(:access) || :admin).to_sym
        attributes[:created_by] ||= user
        attributes[:updated_by] ||= user

        Page.transaction do
          page = new(attributes)
          page.owner = owner if owner
          yield(page) if block_given?
          if user
            if recipients
              share = PageShare.new page, user,
                access: access,
                send_notice: inbox
              share.with recipients
            end
            # Page#owner= creates a user participation for the owner. Creating it
            # here is only needed, if the page is created for a different owner.
            # Also the participation may have been created by PageShare#with.
            # In either case we want "access" to be set to "admin" and "changed_at"
            # set as well (so the page shows up under "Recent Pages" on the dash)
            participation = page.user_participations.select { |part|
              part.user == user
            }.first || page.user_participations.build(user_id: user.id)
            participation.access = ACCESS[:admin]
            participation.changed_at = Time.now
          end
          page
        end
      end
    end


  end # ClassMethods
end # PageExtension::Create


