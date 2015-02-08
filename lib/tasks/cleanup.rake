#
# CLEANUP tasks
#
# Removing data that has become invalid.
#
# In an ideal world these would not be necessary. If you run any of these and
# they actually do sth. you probably want to find out why and remove the cause.
#

namespace :cg do
  namespace :cleanup do
    desc "Run all cleanup tasks"
    task all: [
      :remove_groups_ending_in_plus,
      :remove_group_dups,
      :committees_without_parent,
      :remove_dead_participations,
      :remove_dead_federatings,
      :remove_lost_memberships,
      :remove_empty_posts,
      :remove_unused_tags,
      :merge_duplicate_tags,
      :remove_duplicate_taggings,
      :clear_invalid_email_addresses,
      :remove_dangling_page_histories
    ]

    # There are 6 of these on we.riseup.net from a certain timespan
    # looks like this was caused by a bug that is now fixed.
    desc "Remove groups with names ending in +"
    task(:remove_groups_ending_in_plus => :environment) do
      count = Group.where("name LIKE '%+'").delete_all
      puts "Removed #{count} groups that ended in '+'"
    end

    # This will leave invalid records behind such as GroupParticipations
    # and Memberships whose group does not exist anymore.
    # Rather than instantiating all the groups and calling the depended hooks
    # we clean them up afterwards in other rake tasks.
    desc "Remove duplicate groups"
    task(:remove_group_dups => :environment) do
      empty_dups = Group.joins("JOIN groups AS dup ON groups.name = dup.name").
        where("groups.id NOT IN (SELECT group_id FROM group_participations)")
      later = empty_dups.where("groups.id > dup.id").
        select("groups.id")
      count = Group.where(id: later.map(&:id)).delete_all
      puts "Removed #{count} empty group duplicates that were created later"
      early = empty_dups.where("groups.id < dup.id").
        select("groups.id")
      count = Group.where(id: early.map(&:id)).delete_all
      puts "Removed #{count} empty group duplicates that were created first"
      dups = Group.joins("JOIN groups AS dup ON groups.name = dup.name").
        where("groups.id > dup.id")
      count = Group.where(id: dups.map(&:id)).delete_all
      puts "#{count} group duplicates deleted that were not empty."
    end

    desc "Turn committees without a parent into normal groups"
    task(:committees_without_parent => :environment) do
      Committee.where(parent_id: nil).update_all(type: nil)
    end

    desc "Remove all participations where the entity does not exist anymore"
    task(:remove_dead_participations => :environment) do
      count = UserParticipation.where(dead_entity_sql('user')).delete_all
      count += UserParticipation.where(dead_entity_sql('page')).delete_all
      puts "Removed #{count} User Participations."
      count = GroupParticipation.where(dead_entity_sql('group')).delete_all
      count += GroupParticipation.where(dead_entity_sql('page')).delete_all
      puts "Removed #{count} Group Participations."
    end

    desc "Remove all federatings where the group does not exist anymore"
    task(:remove_dead_federatings => :environment) do
      count = Federating.where(dead_entity_sql('group')).delete_all
      puts "Removed #{count} Federatings with outdated groups."
      count = Federating.where(dead_entity_sql('network', 'groups')).delete_all
      puts "Removed #{count} Federatings with outdated networks."
    end

    desc "Remove all federatings where the group does not exist anymore"
    task(:remove_lost_memberships => :environment) do
      count = Membership.where(dead_entity_sql('group')).delete_all
      puts "Removed #{count} Memberships with outdated groups."
    end

    def dead_entity_sql(type, table = nil)
      table ||= type + 's';
      "#{type}_id NOT IN (SELECT id FROM #{table})"
    end

    desc "Remove empty posts"
    task(:remove_empty_posts => :environment) do
      count = Post.where(body: nil).delete_all
      count += Post.where(body: '').delete_all
      puts "Removed #{count} empty posts"
    end

    desc "Remove unused tags"
    task(:remove_unused_tags => :environment) do
      count = ActsAsTaggableOn::Tag.
        where("id NOT IN (SELECT tag_id FROM taggings)").
        delete_all
      puts "Deleted #{count} unused tags."
    end

    desc "Merge duplicate tags"
    task(:merge_duplicate_tags => :environment) do
      map = ActsAsTaggableOn::Tag.
        joins("JOIN tags AS dup ON tags.name = dup.name").
        where("dup.id > tags.id").
        select("dup.*, tags.id AS target")
      puts "Merging #{map.count} duplicate tags"
      count = 0
      map.each do |dup|
        count += dup.taggings.update_all tag_id: dup.target
      end
      puts "Redirected #{count} taggings."
      Rake::Task["cg:cleanup:remove_unused_tags"].invoke
    end

    desc "Remove duplicate taggings"
    task(:remove_duplicate_taggings => :environment) do
      dup_join = <<-EOSQL
        JOIN taggings AS dups
          ON  dups.tag_id = taggings.tag_id
          AND dups.taggable_id = taggings.taggable_id
          AND dups.taggable_type = taggings.taggable_type
        EOSQL
      dups = ActsAsTaggableOn::Tagging.joins(dup_join).
        where("dups.id > taggings.id").select("dups.id").map(&:id)
      count = ActsAsTaggableOn::Tagging.where(id: dups).delete_all
      puts "Removed #{count} duplicate taggings"
    end

    desc "Clear all invalid email addresses"
    task(:clear_invalid_email_addresses => :environment) do
      invalid = User.where("email IS NOT NULL").select do |u|
        # validate_email_format returns errors - check if there are any
        ValidatesEmailFormatOf.validate_email_format(u.email).present?
      end
      count = User.where(id: invalid.map(&:id)).update_all(email: nil)
      puts "Cleared #{count} invalid email addresses." if count > 0
    end

    desc "Remove page histories where the page is gone"
    task(:remove_dangling_page_histories => :environment) do
      count = PageHistory.where(dead_entity_sql('page')).delete_all
      puts "Removed #{count} page history records without a page"
    end


=begin

under development


    desc "Remove all empty groups with duplicate names"
    task(:remove_empty_duplicate_groups => :environment) do
      puts "Deleting newer empty group duplicates."
      new_dups = duplicates.where("other_group.id < groups.id")
      destroy_empty_groups(new_dups)
      puts "Deleting older empty group duplicates."
      early_dups = duplicates.where("other_group.id > groups.id")
      destroy_empty_groups(early_dups)
    end

    def duplicates
      Group.joins("JOIN groups as other_group ON other_group.name = groups.name")
    end

    def destroy_empty_groups(query)
      puts "Found #{query.count} duplicate groups."
      query.each do |group|
        destroy_if_empty(group)
      end
      puts "#{query.count} duplicate groups left."
    end

    def destroy_if_empty(group)
      return if group.users.count > 1
      return if group.pages.any?
      return if group.version > 1
      group.send(:destroy)
    end

=end
  end
end
