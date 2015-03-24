require 'csv'

module RailsAdminImport
  module RecordImporters
    class CSVImporter
      RecordImporter.register(:csv, self)

      # Default is to downcase headers and add underscores to convert into attribute names
      HEADER_CONVERTER = lambda do |header|
        header.parameterize.underscore
      end

      def initialize(import_model, params)
        if params.has_key?(:file)
          @filename = params[:file].tempfile
        end
        @import_model = import_model
        @header_converter = import_model.config.import.header_converter || HEADER_CONVERTER
      end

      attr_reader :filename, :error

      def valid?
        if filename.nil?
          @error = I18n.t('admin.import.missing_file')
          false
        else
          true
        end
      end

      # A method that yields a hash of attributes for each record to import
      def each_record
        return enum_for(:each_record) unless block_given?
        
        # TODO: set up encoding conversion using the :encoding parameter
        CSV.foreach(filename, headers: true, header_converters: @header_converter) do |row|
          yield convert_to_attributes(row)
        end
      end

      private

      def convert_to_attributes(row)
        row.each_with_object({}) do |(field, value), record|
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
