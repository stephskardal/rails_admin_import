require 'rails_admin_import/import'

module RailsAdminImport
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
