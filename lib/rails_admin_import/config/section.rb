require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
    module Sections
      # Configuration of the navigation view
      class Import < RailsAdmin::Config::Sections::Base
        register_instance_option(:label) do
          :name
        end

        register_instance_option(:mapping_key) do
          :name
        end

        register_instance_option(:excluded_fields) do
          # Don't import PaperTrail versions
          [:versions]
        end

        register_instance_option(:extra_fields) do
          []
        end

        register_instance_option(:included_fields) do
          []
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
