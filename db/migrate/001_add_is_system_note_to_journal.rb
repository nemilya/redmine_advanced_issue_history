#
# 
# rake db:migrate:plugins
#
# or for production mode:
# rake db:migrate_plugins RAILS_ENV=production
#
class AddIsSystemNoteToJournal < ActiveRecord::Migration
  def self.up
    add_column :journals, :is_system_note, :boolean
  end

  def self.down
    remove_column :journals, :is_system_note
  end
end
