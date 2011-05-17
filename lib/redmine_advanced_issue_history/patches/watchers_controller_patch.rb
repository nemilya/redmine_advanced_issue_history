module RedmineAdvancedIssueHistory
  module Patches
    module WatchersControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :destroy, :update_history
          unloadable
        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def destroy_with_update_history
          @watched.set_watcher(User.find(params[:user_id]), false) if request.post?

          # ilya
          if request.post?
            if @watched.respond_to? :issue
              issue = @watched
              user = User.current
              watcher = User.find(params[:user_id])
              note = "Watcher #{watcher.name} was removed"
              journal = Journal.new(:journalized => issue, :user => user, :notes => note)
              journal.save
            end
          end
          # /ilya

          respond_to do |format|
            format.html { redirect_to :back }
            format.js do
              render :update do |page|
                page.replace_html 'watchers', :partial => 'watchers/watchers', :locals => {:watched => @watched}
              end
            end
          end
        end
      end
    end
  end
end
