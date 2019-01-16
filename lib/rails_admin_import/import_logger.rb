module RailsAdminImport
  class ImportLogger
    attr_reader :logger

    def initialize(log_file_name = "rails_admin_import.log")
      if RailsAdminImport.config.logging
        @logger = Logger.new(File.join(Rails.root, "log", log_file_name))
      end
    end

    def info(message)
      if RailsAdminImport.config.logging
        @logger.info message
      end
    end
  end
end
