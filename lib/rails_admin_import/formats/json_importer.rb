module RailsAdminImport
  module Formats
    class JSONImporter < FileImporter
      Formats.register(:json, self)
      Formats.register(:JSON, self)

      # A method that yields a hash of attributes for each record to import
      def each_record
        File.open(filename) do |file|
          data = JSON.load(file)

          if data.is_a? Hash
            # Load array from root key
            data = data[root_key]
          end

          if !data.is_a? Array
            raise ArgumentError, I18n.t("admin.import.invalid_json", root_key: root_key)
          end

          data.each do |record|
            yield record.symbolize_keys
          end
        end
      end

      def root_key
        import_model.model.model_name.element.pluralize
      end
    end
  end
end
