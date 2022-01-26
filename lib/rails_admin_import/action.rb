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

        register_instance_option :controller do
          proc do
            @import_model = RailsAdminImport::ImportModel.new(@abstract_model)

            if request.post?
              format = RailsAdminImport::Formats.from_file(params[:file])
              record_importer = RailsAdminImport::Formats.for(
                format, @import_model, params)

              if record_importer.valid?
                importer = RailsAdminImport::Importer.new(
                  @import_model, params)

                @results = importer.import(record_importer.each)
              else
                flash[:error] = record_importer.error
              end
            end

            render action: @action.template_name
          end
        end

        register_instance_option :link_icon do
          "fas fa-folder-open"
        end
      end
    end
  end
end
