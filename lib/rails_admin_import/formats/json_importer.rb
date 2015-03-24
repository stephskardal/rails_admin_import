module RailsAdminImport
  module Formats
    class JSONImporter
      Formats.register(:json, self)

      def initialize(import_model, params)
        if params.has_key?(:file)
          @filename = params[:file].tempfile
        end
        @import_model = import_model
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
        
        File.open(filename) do |file|
          data = JSON.load(file)
          if !data.is_a? Array
            raise ArgumentError, I18n.t('admin.import.data_not_array')
          end
          data.each do |record|
            yield record.symbolize_keys
          end
        end
      end
    end
  end
end
