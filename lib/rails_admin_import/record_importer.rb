module RailsAdminImport
  class RecordImporter
    def self.add_importer(format, klass)
      @importers ||= {}
      @importers[format] = klass
    end

    def self.for(format, *args)
      @importers.fetch(format).new(*args)
    end
  end
end

require 'rails_admin_import/record_importers/csv'
