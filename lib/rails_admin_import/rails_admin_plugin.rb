# Load the Rails Admin gem if not already done
require "rails_admin"

# Add the Import action
require "rails_admin_import/action"

# Add the import configuration section for models
require "rails_admin_import/config/sections/import"

# Register the configuration adapter for Rails Admin
# to allow configure_with(:import)
module RailsAdminImport
  module Extension
    class ConfigurationAdapter < SimpleDelegator
      def initialize
        super RailsAdminImport::Config
      end
    end
  end
end

RailsAdmin.add_extension :import, RailsAdminImport::Extension,
  configuration: true
