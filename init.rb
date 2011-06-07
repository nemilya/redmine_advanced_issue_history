require 'redmine'

require 'journals_helper_patch' # history are not ediatable for system notes

Redmine::Plugin.register :redmine_advanced_issue_history do
  name 'Redmine Advanced Issue History plugin'
  author 'Ilya Nemihin'
  description 'New events store in Issue history'
  version '0.0.9'
  url 'https://github.com/nemilya/redmine_advanced_issue_history'
  author_url ''
end


require 'dispatcher'
Dispatcher.to_prepare :redmine_advanced_issue_history do
  require_dependency 'issue_relations_controller'
  IssueRelationsController.send(:include, RedmineAdvancedIssueHistory::Patches::IssueRelationsControllerPatch)

  require_dependency 'watcher'
  Watcher.send(:include, RedmineAdvancedIssueHistory::Patches::WatcherPatch)

  require_dependency 'watchers_controller'
  WatchersController.send(:include, RedmineAdvancedIssueHistory::Patches::WatchersControllerPatch)
end

require 'redmine_advanced_issue_history/hooks/controller_issues_new_after_save_hook'
