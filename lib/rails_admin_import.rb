require "rails_admin_import/engine"
require "rails_admin_import/import_model"
require "rails_admin_import/formats"
require "rails_admin_import/importer"
require "rails_admin_import/config"
require "rails_admin_import/rails_admin_plugin"

module RailsAdminImport
  def self.config(entity = nil, &block)
    if entity
      RailsAdminImport::Config.model(entity, &block)
    elsif block_given? && ENV["SKIP_RAILS_ADMIN_INITIALIZER"] != "true"
      block.call(RailsAdminImport::Config)
    else
      RailsAdminImport::Config
    end
  end

  def self.reset
    RailsAdminImport::Config.reset
  end
end

