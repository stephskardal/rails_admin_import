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
          proc do
            @import_model = RailsAdminImport::ImportModel.new(@abstract_model)

            if request.post?
              record_importer = RailsAdminImport::RecordImporter.for(:csv, @import_model, params)
              if record_importer.valid?
                importer = RailsAdminImport::Importer.new(@import_model, params)
                @results = importer.import(record_importer.each_record)

                imported = @results[:success]
                not_imported = @results[:error]
                @results[:success_message] = t('admin.flash.successful', name: pluralize(imported.count, @model_config.label), action: t('admin.actions.import.done')) unless imported.empty?
                @results[:error_message] = t('admin.flash.error', name: pluralize(not_imported.count, @model_config.label), action: t('admin.actions.import.done')) unless not_imported.empty?
              else
                flash[:error] = record_importer.error
              end
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

