source "http://rubygems.org"

# CI dependencies
gem 'rails', '~> 6.1'
gem 'rails_admin', '~> 3.0.0'
gem 'sassc-rails'

case ENV['CI_ORM']
when 'mongoid'
  gem 'mongoid', '~> 7.3'
  gem 'kaminari-mongoid'
else
  case ENV['CI_DB_ADAPTER']
  when 'mysql2'
    gem 'mysql2', '~> 0.5.3'
  when 'postgresql'
    gem 'pg', '>= 0.18'
  else
    gem 'sqlite3', '~> 1.4.2'
  end
end

group :test do
  gem 'rspec', '~> 3.10'
  gem 'rspec-rails', '~> 5.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'factory_bot', '< 6.4'
  gem 'database_cleaner-active_record', require: false
  gem 'database_cleaner-mongoid', require: false
end

gem 'rubygems-tasks'

# Declare your gem's dependencies in rails_admin_import.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec
