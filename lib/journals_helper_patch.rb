require_dependency 'journals_helper'

module JournalsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :render_notes, :is_system_note
    end
  end

  module InstanceMethods
    def render_notes_with_is_system_note(issue, journal, options={})
      content = ''
      editable = User.current.logged? && (User.current.allowed_to?(:edit_issue_notes, issue.project) || (journal.user == User.current && User.current.allowed_to?(:edit_own_issue_notes, issue.project)))
      links = []
      # changed
      if !journal.notes.blank? && (journal.is_system_note.nil? || !journal.is_system_note)
        links << link_to_remote(image_tag('comment.png'),
                                { :url => {:controller => 'journals', :action => 'new', :id => issue, :journal_id => journal} },
                                :title => l(:button_quote)) if options[:reply_links]
        links << link_to_in_place_notes_editor(image_tag('edit.png'), "journal-#{journal.id}-notes", 
                                               { :controller => 'journals', :action => 'edit', :id => journal },
                                                  :title => l(:button_edit)) if editable
      end
      content << content_tag('div', links.join(' '), :class => 'contextual') unless links.empty?
      content << textilizable(journal, :notes)
      css_classes = "wiki"
      css_classes << " editable" if editable
      content_tag('div', content, :id => "journal-#{journal.id}-notes", :class => css_classes)
    end
  end
end

JournalsHelper.send(:include, JournalsHelperPatch)