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
            # make sure class has import-related methods
            @abstract_model.model.send :include, ::RailsAdminImport::Import

            @file_formats_accepted = @abstract_model.model.file_formats_accepted

            @response = {}


            # debugger

            if request.post?
              # if !params.has_key?(:input)
              #   return results = { :success => [], :error => ["You must select a file."] }
              # end

              associated_map = {}
              # @abstract_model.model.belongs_to_fields.flatten.each do |field|
              #   associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field]).to_s] = c.id; hash }
              # end
              # @abstract_model.model.many_fields.flatten.each do |field|
              #   associated_map[field] = field.to_s.classify.constantize.all.inject({}) { |hash, c| hash[c.send(params[field]).to_s] = c; hash }
              # end

              if params[:upload]
                results = @abstract_model.model.rails_admin_import({
                  input: params[:upload],
                  type: :upload,
                  format: params[:input_format].to_sym, 
                  lookup: params[:update_lookup],
                  associated_map: associated_map,
                  role: _attr_accessible_role, 
                  user: _current_user
                })
              elsif params[:raw_text]
                results = @abstract_model.model.rails_admin_import({
                  input: params[:raw_text],
                  type: :raw_text,
                  format: params[:input_format].to_sym,
                  lookup: params[:update_lookup],
                  associated_map: associated_map,
                  role: _attr_accessible_role, 
                  user: _current_user
                })
              elsif params[:url]
                results = @abstract_model.model.rails_admin_import({
                  input: params[:url],
                  type: :url,
                  format: params[:input_format].to_sym,
                  lookup: params[:update_lookup],
                  associated_map: associated_map,
                  role: _attr_accessible_role, 
                  user: _current_user
                })
              else
                results = { :success => [], :error => ["Failed"] }
              end

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
