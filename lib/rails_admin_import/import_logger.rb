module RailsAdminImport
  class ImportLogger
    attr_reader :logger

    def initialize(log_file_name = 'rails_admin_import.log')
      @logger = Logger.new("#{Rails.root}/log/#{log_file_name}") if RailsAdminImport.config.logging
    end
    
    def info(message)
      @logger.info message if RailsAdminImport.config.logging
    end
 
  end
end
