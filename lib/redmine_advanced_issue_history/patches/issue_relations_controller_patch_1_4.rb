module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :create,  :update_history
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

        def create_with_update_history
          # based on redmine 1.4.4
          @relation = IssueRelation.new(params[:relation])
          @relation.issue_from = @issue
          if params[:relation] && m = params[:relation][:issue_to_id].to_s.strip.match(/^#?(\d+)$/)
            @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
          end
          saved = @relation.save

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
            format.api {
              if saved
                render :action => 'show', :status => :created, :location => relation_url(@relation)
              else
                render_validation_errors(@relation)
              end
            }
          end
        end


        def destroy_with_update_history
          # based on redmine 1.4.4

          raise Unauthorized unless @relation.deletable?
          @relation.destroy

          # ilya
          note = "Relation '#{@relation.type}' to '#{@relation.issue_to}' was destroyed"
          journal = Journal.new(:journalized => @relation.issue_from, :user => User.current, :notes => note, :is_system_note=> true)
          journal.save

          note = "Relation '#{@relation.type}' to '#{@relation.issue_from}' was destroyed"
          journal = Journal.new(:journalized => @relation.issue_to, :user => User.current, :notes => note, :is_system_note=> true)
          journal.save
          # /ilya

          respond_to do |format|
            format.html { redirect_to issue_path } # TODO : does this really work since @issue is always nil? What is it useful to?
            format.js   { 
              render(:update) { |page|

                # ilya
                @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
                @journals.each_with_index {|j,i| j.indice = i+1}
                @journals.reverse! if User.current.wants_comments_in_reverse_order?
                page.replace_html "history", :partial => 'issues/history', :locals => { :issue => @issue, :journals => @journals }
                # /ilya
                
                page.remove "relation-#{@relation.id}"
              }
            }
            format.api  { head :ok }
          end
        end


      end
    end
  end
end
