require 'redmine'

Redmine::Plugin.register :redmine_advanced_issue_history do
  name 'Redmine Advanced Issue History plugin'
  author 'Ilya Nemihin'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url ''
  author_url ''
end


require 'dispatcher'
Dispatcher.to_prepare :redmine_advanced_issue_history do
  require_dependency 'issue_relations_controller'
  IssueRelationsController.send(:include, RedmineAdvancedIssueHistory::Patches::IssueRelationsControllerPatch)

  require_dependency 'issue_relation'
  IssueRelation.send(:include, RedmineAdvancedIssueHistory::Patches::IssueRelationPatch)

  require_dependency 'watcher'
  Watcher.send(:include, RedmineAdvancedIssueHistory::Patches::WatcherPatch)

end
