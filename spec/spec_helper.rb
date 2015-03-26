# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'
CI_ORM = (ENV['CI_ORM'] || :active_record).to_sym

require File.expand_path('../dummy_app/config/environment', __FILE__)

require 'rspec/rails'
require 'database_cleaner'

if CI_ORM == :active_record
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end

  silence_stream(STDOUT) do
    ActiveRecord::Migrator.migrate File.expand_path('../../dummy_app/db/migrate/', __FILE__)
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RSpec::Matchers

  config.before do |example|
    DatabaseCleaner.strategy = (CI_ORM == :mongoid || example.metadata[:js]) ? :truncation : :transaction

    DatabaseCleaner.start
    RailsAdmin::Config.reset
    RailsAdmin::AbstractModel.reset
    RailsAdmin::Config.yell_for_non_accessible_fields = false
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
