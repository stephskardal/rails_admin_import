module RailsAdminImport
  module Formats
    class << self
      def register(format, klass)
        @registry[format.to_s] = klass
      end

      def for(format, *args)
        @registry.fetch(format.to_s, DummyImporter).new(*args)
      end

      def all
        @registry.keys
      end

      def reset
        @registry = {}
      end
    end

    reset
  end
end

require "rails_admin_import/formats/dummy_importer"
require "rails_admin_import/formats/file_importer"
require "rails_admin_import/formats/csv_importer"
require "rails_admin_import/formats/json_importer"
require "rails_admin_import/formats/xlsx_importer"
