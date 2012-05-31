module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :new,     :update_history
          alias_method_chain :destroy, :update_history
          unloadable
          helper :journals
          helper :issues
          include JournalsHelper   
          include IssuesHelper   
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def new_with_update_history
          @relation = IssueRelation.new(params[:relation])
          @relation.issue_from = @issue
          if params[:relation] && m = params[:relation][:issue_to_id].to_s.match(/^#?(\d+)$/)
            @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
          end
          @relation.save if request.post?

          # ilya
          if @relation.errors.empty? && request.post?
            note = "Relation '#{@relation.type}' to '#{@relation.issue_to}' was created"
            journal = Journal.new(:journalized => @issue, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save

            note = "Relation '#{@relation.type}' to '#{@issue}' was created"
            journal = Journal.new(:journalized => @relation.issue_to, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save
          end
          # /ilya

          respond_to do |format|
            format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
            format.js do
              @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
              render :update do |page|
                page.replace_html "relations", :partial => 'issues/relations'
                # ilya
                @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
                @journals.each_with_index {|j,i| j.indice = i+1}
                @journals.reverse! if User.current.wants_comments_in_reverse_order?
                page.replace_html "history", :partial => 'issues/history', :locals => { :issue => @issue, :journals => @journals }
                # /ilya
                if @relation.errors.empty?
                  page << "$('relation_delay').value = ''"
                  page << "$('relation_issue_to_id').value = ''"
                end
              end
            end
          end
        end


        def destroy_with_update_history
          relation = IssueRelation.find(params[:id])
          if request.post? && @issue.relations.include?(relation)
            relation.destroy

            # ilya
            note = "Relation '#{relation.type}' to '#{relation.issue_to}' was destroyed"
            journal = Journal.new(:journalized => relation.issue_from, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save

            note = "Relation '#{relation.type}' to '#{relation.issue_from}' was destroyed"
            journal = Journal.new(:journalized => relation.issue_to, :user => User.current, :notes => note, :is_system_note=> true)
            journal.save
            # /ilya

            @issue.reload
          end

          respond_to do |format|
            format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
            format.js {
              @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
              render(:update) do |page| 
                # ilya
                @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
                @journals.each_with_index {|j,i| j.indice = i+1}
                @journals.reverse! if User.current.wants_comments_in_reverse_order?
                page.replace_html "history", :partial => 'issues/history', :locals => { :issue => @issue, :journals => @journals }
                # /ilya
                page.replace_html "relations", :partial => 'issues/relations'
              end
            }
          end
        end


      end
    end
  end
end
