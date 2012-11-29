require 'redmine'

require 'journals_helper_patch' # history are not ediatable for system notes

Redmine::Plugin.register :redmine_advanced_issue_history do
  name 'Redmine Advanced Issue History plugin'
  author 'Ilya Nemihin'
  description 'New events store in Issue history'
  version '0.1'
  url 'https://github.com/nemilya/redmine_advanced_issue_history'
  author_url ''
end


require 'dispatcher'
Dispatcher.to_prepare :redmine_advanced_issue_history do
  if Redmine::VERSION.to_s >= '1.4.0'
    # tested for 1.4.4
    require 'redmine_advanced_issue_history/patches/issue_relations_controller_patch_1_4'
  else
    # redmine 1.2.x
    require 'redmine_advanced_issue_history/patches/issue_relations_controller_patch'
  end
  IssueRelationsController.send(:include, RedmineAdvancedIssueHistory::Patches::IssueRelationsControllerPatch)

  require_dependency 'watcher'
  Watcher.send(:include, RedmineAdvancedIssueHistory::Patches::WatcherPatch)

  require_dependency 'watchers_controller'
  WatchersController.send(:include, RedmineAdvancedIssueHistory::Patches::WatchersControllerPatch)
end

require 'redmine_advanced_issue_history/hooks/controller_issues_new_after_save_hook'
