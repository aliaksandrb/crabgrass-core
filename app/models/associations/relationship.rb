# user to user relationship

class Relationship < ActiveRecord::Base
  belongs_to :user
  belongs_to :contact, class_name: 'User', foreign_key: :contact_id
  belongs_to :discussion, dependent: :destroy, inverse_of: :relationships

  # mark as read or unread the discussion on this relationship
  def mark!(as)
    # set a new value for the unread_count field
    new_unread_count = nil

    if as == :read
      new_unread_count = 0
    elsif as == :unread
      # mark unread if necessary
      if self.unread_count.blank? or self.unread_count < 1
        new_unread_count = 1
      end
    end

    self.update_attribute(:unread_count, new_unread_count) if new_unread_count
  end

  def discussion
    super || init_discussion
  end

  def init_discussion
    create_discussion.tap do |discuss|
      inverse.update_attribute :discussion, discuss
      save
    end
  end

  def inverse
    @inverse ||= Relationship.where(user_id: contact, contact_id: user).first
  end
end
