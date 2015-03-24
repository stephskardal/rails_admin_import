module RailsAdminImport
  module RecordImporter
    @@registry = {}

    def self.register(format, klass)
      @@registry[format] = klass
    end

    def self.for(format, *args)
      @@registry.fetch(format, DummyImporter).new(*args)
    end

    class DummyImporter
      def initialize(*args)
      end

      def valid
        false
      end

      def error
        I18n.t('admin.import.invalid_format')
      end
    end
  end
end

require 'rails_admin_import/record_importers/csv_importer'
