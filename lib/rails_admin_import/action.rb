require "rails_admin/config/actions"

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
              record_importer = RailsAdminImport::Formats.for(params[:import_format],
                                                              @import_model,
                                                              params)
              if record_importer.valid?
                importer = RailsAdminImport::Importer.new(@import_model,
                                                          params)
                @results = importer.import(record_importer.each_record)

                imported = @results[:success]
                not_imported = @results[:error]
                message = lambda do |type, array|
                    t("admin.flash.#{type}",
                      name: pluralize(array.size, @model_config.label),
                      action: t("admin.actions.import.done"))
                end
                unless imported.empty?
                  @results[:success_message] = message.call("successful", imported)
                end
                unless not_imported.empty?
                  @results[:error_message] = message.call("error", not_imported)
                end
              else
                flash[:error] = record_importer.error
              end
            end

            render action: @action.template_name
          end
        end

        register_instance_option :link_icon do
          "icon-folder-open"
        end
      end
    end
  end
end
