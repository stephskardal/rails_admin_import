require 'rails_admin_import/config'
require 'rails_admin_import/config/base'

module RailsAdminImport
  module Config
    class Model < RailsAdminImport::Config::Base
      def initialize(entity)
      end

      register_instance_option(:label) do
        :id
      end

      register_instance_option(:included_fields) do
        []
      end

      register_instance_option(:excluded_fields) do
        []
      end

      register_instance_option(:extra_fields) do
        []
      end
      
      register_instance_option(:update_lookup_field) do
        nil
      end
      
      # params to callback will be (model, row, map)
      register_instance_option(:before_import_save) do
        nil
      end
      
    end
  end
end
