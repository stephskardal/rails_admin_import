module RailsAdminImport
  module RecordImporter
    @@registry = {}

    def self.register(format, klass)
      @@registry[format] = klass
    end

    def self.for(format, *args)
      @@registry.fetch(format).new(*args)
    end
  end
end

require 'rails_admin_import/record_importers/csv'
