require 'rails_admin/config/actions'

module RailsAdmin
  module Config
    module Actions
      class Import < Base
        RailsAdmin::Config::Actions.register(self)
        
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        # FIXME: Remove. this kind of option doesn't appear in other actions
        register_instance_option :label do
          [:name, :id]
        end

        register_instance_option :mapping_key do
          :name
        end

        register_instance_option :controller do
          Proc.new do
            # TODO: replace RailsAdminImport.config(@abstract_model.model) by @model_config
            @importer = RailsAdminImport::Importer.new(@abstract_model, RailsAdminImport.config(@abstract_model.model))

            if request.post?
              @results = @importer.run_import(params)

              imported = @results[:success]
              not_imported = @results[:error]
              @results[:success_message] = t('admin.flash.successful', name: pluralize(imported.count, @model_config.label), action: t('admin.actions.import.done')) unless imported.empty?
              @results[:error_message] = t('admin.flash.error', name: pluralize(not_imported.count, @model_config.label), action: t('admin.actions.import.done')) unless not_imported.empty?
            end

            render :action => @action.template_name
          end
        end

        register_instance_option :link_icon do
          'icon-folder-open'
        end
      end
    end
  end
end

