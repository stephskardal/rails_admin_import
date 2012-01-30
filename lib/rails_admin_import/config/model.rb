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

      register_instance_option(:excluded_fields) do
        []
      end

      register_instance_option(:extra_fields) do
        []
      end
    end
  end
end
