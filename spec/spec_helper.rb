# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'
CI_ORM = (ENV['CI_ORM'] || :active_record).to_sym

require File.expand_path('../dummy_app/config/environment', __FILE__)

require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RSpec::Matchers
  
  config.include ActionDispatch::TestProcess
  config.fixture_path = File.expand_path "../fixtures", __FILE__

  DatabaseCleaner.strategy = :truncation
  config.before do
    
    DatabaseCleaner.start
    RailsAdmin::Config.reset
    RailsAdmin::AbstractModel.reset
    RailsAdminImport.reset

    RailsAdmin.config do |config|
      config.actions do
        all
        import
      end
    end

    # Add fixture_path to examples when running with Mongoid because
    # ActiveRecord::TestFixtures is not included
    # This is necessary for fixture_file_upload to find files
    unless self.class.respond_to?(:fixture_path)
      self.class.instance_eval do
        def fixture_path
          RSpec.configuration.fixture_path
        end
      end
    end
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean
  end
end

