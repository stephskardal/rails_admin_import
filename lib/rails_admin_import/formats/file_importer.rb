module RailsAdminImport
  module Formats
    class FileImporter
      def initialize(import_model, params)
        if params.has_key?(:file)
          @filename = params[:file].tempfile
        end
        @import_model = import_model
      end

      attr_reader :filename, :error, :import_model

      def valid?
        if filename.nil?
          @error = I18n.t("admin.import.missing_file")
          false
        else
          true
        end
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        if RailsAdminImport.config.logging && filename
          FileUtils.copy(filename, File.join(Rails.root, "log", "import", "#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv"))
        end

        each_record(&block)
      end

      def each_record
        raise "Implement each_record in subclasses"
      end
    end
  end
end
