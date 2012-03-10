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
        
        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          Proc.new do
            @response = {}

            if request.post?
              results = @abstract_model.model.run_import(params)
              @response[:notice] = results[:success].join("<br />").html_safe if results[:success].any?
              @response[:error] = results[:error].join("<br />").html_safe if results[:error].any?
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
