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
  config.before do |example|
    
    DatabaseCleaner.start
    if example.metadata[:reset_config]
      RailsAdmin::Config.reset
      RailsAdmin::AbstractModel.reset
    end
    RailsAdmin::Config.yell_for_non_accessible_fields = false
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
