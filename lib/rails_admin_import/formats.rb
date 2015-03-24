module RailsAdminImport
  module Formats
    @@registry = {}

    def self.register(format, klass)
      @@registry[format.to_s] = klass
    end

    def self.for(format, *args)
      @@registry.fetch(format.to_s, DummyImporter).new(*args)
    end

    def self.all
      @@registry.keys
    end

    def self.default
      all.first
    end

    class DummyImporter
      def initialize(*args)
      end

      def valid?
        false
      end

      def error
        I18n.t('admin.import.invalid_format')
      end
    end
  end
end

require 'rails_admin_import/formats/csv_importer'
require 'rails_admin_import/formats/json_importer'
