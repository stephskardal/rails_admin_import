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
          copy_uploaded_file_to_log_dir
        end

        each_record(&block)
      end

      private

      def each_record
        raise "Implement each_record in subclasses"
      end

      def copy_uploaded_file_to_log_dir
        copy_filename = "#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-import.csv"
        dir_path = File.join(Rails.root, "log", "import")
        FileUtils.mkdir_p(dir_path)
        copy_path = File.join(dir_path, copy_filename)
        FileUtils.copy(filename, copy_path)
      end
    end
  end
end
