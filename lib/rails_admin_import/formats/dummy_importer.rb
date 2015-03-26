module RailsAdminImport
  module Formats
    class DummyImporter
      def initialize(*)
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
