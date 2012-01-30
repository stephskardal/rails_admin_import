require 'rails_admin_import/import'
require 'rails_admin_import/config'

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

  class Engine < Rails::Engine
=begin
    config.to_prepare do
      ActiveRecord::Base.send(:subclasses).each do |model|
      #  model.class_eval do
      #    include ::RailsAdminImport::Import
      #  end 
      #  model.send :include, ::RailsAdminImport::Import
      end
    end

    initializer "rails_admin_import.rails_admin_config" do |app|
      #RailsAdmin.config do |config|
        #config.actions do
        #  collection :import do
        #  end
        #end 
      #end
    end
=end
  end
end
