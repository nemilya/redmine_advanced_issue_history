module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def after_create
          p 'after_create'
          note = "Relation type '#{self.type}' to '#{self.issue_to}' was created"
          journal = Journal.new(:journalized => self.issue_from, :user => User.current, :notes => note)
          journal.save
        end

        def after_destroy
          p 'after_destroy'
          note = "Relation type '#{self.type}' to '#{self.issue_to}' was destroyed"
          journal = Journal.new(:journalized => self.issue_from, :user => User.current, :notes => note)
          journal.save
        end

      end
    end
  end
end
