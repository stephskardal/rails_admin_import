module RailsAdminImport
  module Formats
    class JSONImporter < FileImporter
      Formats.register(:json, self)

      # A method that yields a hash of attributes for each record to import
      def each_record
        File.open(filename) do |file|
          data = JSON.load(file)
          if !data.is_a? Array
            raise ArgumentError, I18n.t("admin.import.data_not_array")
          end
          data.each do |record|
            yield record.symbolize_keys
          end
        end
      end
    end
  end
end
