module RedmineAdvancedIssueHistory
  module Hooks
    class ControllerIssuesNewAfterSaveHook < Redmine::Hook::ViewListener
      # Context:
      # * :issue => Issue being saved
      # * :params => HTML parameters
      #
      def controller_issues_new_after_save(context={})
        issue = context[:issue]
        unless issue.parent.nil?
          parent_issue = issue.parent
          user = User.current
          note = "Sub tast '#{issue}' was added"
          journal = Journal.new(:journalized => parent_issue, :user => user, :notes => note)
          journal.save
        end
      end
    end
  end
end
