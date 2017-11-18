require "csv"

module RailsAdminImport
  module Formats
    class XLSXImporter < FileImporter
      Formats.register(:xlsx, self)
      Formats.register(:XLSX, self)

      autoload :SimpleXlsxReader, "simple_xlsx_reader"

      def initialize(import_model, params)
        super
        @header_converter = RailsAdminImport.config.header_converter
      end

      # A method that yields a hash of attributes for each record to import
      def each_record
        doc = SimpleXlsxReader.open(filename)
        sheet = doc.sheets.first
        @headers = convert_headers(sheet.headers)
        sheet.data.each do |row|
          yield convert_to_attributes(row)
        end
      end

      private

      def convert_headers(headers)
        headers.map do |h|
          @header_converter.call(h || "")
        end
      end

      def convert_to_attributes(row)
        row_with_headers = @headers.zip(row)
        row_with_headers.each_with_object({}) do |(field, value), record|
          next if field.nil?
          field = field.to_sym
          if import_model.has_multiple_values?(field)
            field = import_model.pluralize_field(field)
            (record[field] ||= []) << value
          else
            record[field] = value
          end
        end
      end
    end
  end
end
