require 'rails_admin_import/config'
require 'rails_admin_import/config/base'

module RailsAdminImport
  module Config
    class Model < RailsAdminImport::Config::Base
      def initialize(entity)
      end

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
    end
  end
end
