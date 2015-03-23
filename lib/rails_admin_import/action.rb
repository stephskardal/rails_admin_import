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
            @importer = RailsAdminImport::Importer.new(@abstract_model)

            if request.post?
              begin
                raise ArgumentError if !params.has_key?(:file)
                record_importer = RailsAdminImport::RecordImporter.for(:csv, params[:file].tempfile)

                @results = @importer.run_import(params.merge(record_importer: record_importer))

                imported = @results[:success]
                not_imported = @results[:error]
                @results[:success_message] = t('admin.flash.successful', name: pluralize(imported.count, @model_config.label), action: t('admin.actions.import.done')) unless imported.empty?
                @results[:error_message] = t('admin.flash.error', name: pluralize(not_imported.count, @model_config.label), action: t('admin.actions.import.done')) unless not_imported.empty?
              rescue ArgumentException
                flash[:error] = t('admin.import.missing_file')
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

