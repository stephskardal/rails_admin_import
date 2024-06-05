require "csv"
require "charlock_holmes"

module RailsAdminImport
  module Formats
    class CSVImporter < FileImporter
      Formats.register(:csv, self)
      Formats.register(:CSV, self)

      autoload :CharDet, "rchardet"

      def initialize(import_model, params)
        super
        @encoding = params[:encoding]
        @header_converter = RailsAdminImport.config.header_converter
      end

      # A method that yields a hash of attributes for each record to import
      def each_record
        CSV.foreach(filename, **csv_options) do |row|
          attr = convert_to_attributes(row)
          yield attr unless attr.all? { |field, value| value.blank? }
        end
      end

      private

      def csv_options
        defaults = RailsAdminImport.config.csv_options
        options = {
          headers: true,
          header_converters: @header_converter,
          encoding: encoding,
        }

        defaults.merge(options)
      end

      def encoding
        from_encoding =
          if !@encoding.blank?
            @encoding
          else
            detect_encoding
          end

        from_encoding = "bom|" + from_encoding if from_encoding.start_with?("UTF-")

        to_encoding = import_model.abstract_model.encoding

        if from_encoding && from_encoding != to_encoding
          "#{from_encoding}:#{to_encoding}"
        else
          nil
        end
      end

      def detect_encoding
        charset = CharlockHolmes::EncodingDetector.detect File.read(filename)
        if charset[:confidence] > 0.6
          from_encoding = charset[:encoding]
          from_encoding = "UTF-8" if from_encoding == "ascii"
        end
        from_encoding
      end

      def convert_to_attributes(row)
        row.each_with_object({}) do |(field, value), record|
          next if field.blank?
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
