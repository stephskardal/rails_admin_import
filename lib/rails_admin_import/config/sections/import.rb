require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
    module Sections
      # Configuration of the navigation view
      class Import < RailsAdmin::Config::Sections::Base
        register_instance_option(:mapping_key) do
          :name
        end

        # Defaults to converting header to lowercase with underscore
        register_instance_option(:header_converter) do
          nil
        end

        register_instance_option(:default_excluded_fields) do
          [:id, :_id, :created_at, :updated_at]
        end
      end
    end
  end
end

section = RailsAdmin::Config::Sections::Import
name = :import

RailsAdmin::Config::Model.send(:define_method, name) do |&block|
  @sections = {} unless @sections
  @sections[name] = section.new(self) unless @sections[name]
  @sections[name].instance_eval(&block) if block
  @sections[name]
end
