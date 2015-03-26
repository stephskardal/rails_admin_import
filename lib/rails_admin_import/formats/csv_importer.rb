require "csv"
require "rchardet"

module RailsAdminImport
  module Formats
    class CSVImporter
      Formats.register(:csv, self)

      # Default is to downcase headers and add underscores to convert into attribute names
      HEADER_CONVERTER = lambda do |header|
        header.parameterize.underscore
      end

      def initialize(import_model, params)
        if params.has_key?(:file)
          @filename = params[:file].tempfile
        end
        @encoding = params[:encoding]
        @import_model = import_model
        @header_converter = import_model.config.header_converter || HEADER_CONVERTER
      end

      attr_reader :filename, :error

      def valid?
        if filename.nil?
          @error = I18n.t("admin.import.missing_file")
          false
        else
          true
        end
      end

      # A method that yields a hash of attributes for each record to import
      def each_record
        return enum_for(:each_record) unless block_given?

        CSV.foreach(filename, csv_options) do |row|
          yield convert_to_attributes(row)
        end
      end

      private

      attr_reader :import_model

      def csv_options
        {
          headers: true,
          header_converters: @header_converter
        }.tap do |options|
          add_encoding!(options)
        end
      end

      def add_encoding!(options)
        from_encoding = 
          if !@encoding.blank?
            @encoding
          else
            detect_encoding
          end

        to_encoding = import_model.abstract_model.encoding
        if from_encoding && from_encoding != to_encoding
          options[:encoding] = "#{from_encoding}:#{to_encoding}"
        end
      end

      def detect_encoding
        charset = CharDet.detect File.read(filename)
        if charset['confidence'] > 0.6
          from_encoding = charset['encoding']
          from_encoding = 'UTF-8' if from_encoding == 'ascii'
        end
        from_encoding
      end

      def convert_to_attributes(row)
        row.each_with_object({}) do |(field, value), record|
          break if field.nil?
          field = field.to_sym
          if @import_model.has_multiple_values?(field)
            (record[field] ||= []) << value
          else
            record[field] = value
          end
        end
      end
    end
  end
end
