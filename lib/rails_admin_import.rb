require "rails_admin_import/engine"
require "rails_admin_import/import"
require "rails_admin_import/config"

module RailsAdminImport
  def self.config(entity = nil, &block)
    if entity
      RailsAdminImport::Config.model(entity, &block)
    elsif block_given? && ENV['SKIP_RAILS_ADMIN_INITIALIZER'] != "true"
      block.call(RailsAdminImport::Config)
    else
      RailsAdminImport::Config
    end
  end

  def self.reset
    RailsAdminImport::Config.reset
  end
end

require 'rails_admin/config/actions'

module RailsAdmin
  module Config
    module Actions
      class Import < Base
        RailsAdmin::Config::Actions.register(self)
        
        register_instance_option(:collection) do
          true
        end

        register_instance_option(:http_methods) do
          [:get, :post]
        end

        register_instance_option(:link_icon) do
          'icon-folder-open'
        end

        register_instance_option :controller do
          Proc.new do
            @response = {}
            text = ""

            # @abstract_model -> Post
            # @abstract_model.model -> Post(id: integer, title: string, slug: string, body: text, body_html: text, active: boolean, approved_comments_count: integer, cached_tag_list: string, published_at: datetime, created_at: datetime, updated_at: datetime, edited_at: datetime)
            
            # make sure class has import-related methods
            @abstract_model.model.send :include, ::RailsAdminImport::Import

            if request.post?
              
              if !params.has_key?(:file)
                return results = { :success => [], :error => ["You must select a file."] }

              elsif params[:file].is_a? String
                # text = open(params[:file]).read()

                results = @abstract_model.model.rss_import(params, _attr_accessible_role, _current_user)

              elsif params[:file].is_a? ActionDispatch::Http::UploadedFile
                # text = File.read(params[:file].tempfile)

                if params[:file].content_type == "text/csv"
                  results = @abstract_model.model.csv_import(params, _attr_accessible_role, _current_user)
                end
              end

              # results             = @abstract_model.model.run_import(params, _attr_accessible_role, _current_user)
              @response[:notice]  = results[:success].join("<br />").html_safe  if results[:success].any?
              @response[:error]   = results[:error].join("<br />").html_safe    if results[:error].any?
            end

            render :action => @action.template_name
          end
        end
      end
    end
  end
end
