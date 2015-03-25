module RailsAdminImport
  module Formats
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
