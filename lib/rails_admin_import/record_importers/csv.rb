require 'csv'

module RailsAdminImport
  module RecordImporters
    class CSV
      RecordImporter.register(:csv, self)

      def initialize(filename)
        @csv = CSV.open(filename, headers: true, header_converters: HEADER_CONVERTER)

        # TODO: set up encoding conversion
        # csv_string = csv_string.encode(@encoding_to, @encoding_from, invalid: :replace, undef: :replace, replace: '?')
      end

      def each_record
        return enum_for(:each_record) unless block_given?
        
        @csv.each do |row|
          yield convert_to_hash(row)
        end
      end

      private

      def convert_to_hash(row)
        row.each_with_object({}) do |(header, value), record|
          # When multiple columns with the same name exist, wrap the values in an array
          if record.has_key?(header)
            record[header] = [*record[header], value]
          else
            record[header] = value
          end
        end
      end
    end
  end
end
