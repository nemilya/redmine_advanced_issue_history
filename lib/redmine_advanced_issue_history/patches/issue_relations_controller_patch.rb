module RedmineAdvancedIssueHistory
  module Patches
    module IssueRelationsControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          # unloadable
          helper :journals
          include JournalsHelper   
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def new
          @relation = IssueRelation.new(params[:relation])
          @relation.issue_from = @issue
          if params[:relation] && m = params[:relation][:issue_to_id].to_s.match(/^#?(\d+)$/)
            @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
          end
          @relation.save if request.post?

          # ilya
#          if @relation.errors.empty? && request.post?
#            note = "Relation type '#{@relation.type}' to '#{@relation.issue_to}' was created"
#            journal = Journal.new(:journalized => @issue, :user => User.current, :notes => note)
#            journal.save
#          end
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

      end
    end
  end
end
