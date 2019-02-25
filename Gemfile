source "http://rubygems.org"

# CI dependencies
gem 'rails', '~> 5.1'
gem 'rails_admin'

case ENV['CI_ORM']
when 'mongoid'
  gem 'mongoid', '~> 6.0'
else
  case ENV['CI_DB_ADAPTER']
  when 'mysql2'
    gem 'mysql2', '~> 0.4.4'
  when 'postgresql'
    gem 'pg', '>= 0.14'
  else
    gem 'sqlite3', '~> 1.3.13'
  end
end

group :test do
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails', '~> 3.0'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
end

gem 'rubygems-tasks'

# Declare your gem's dependencies in rails_admin_import.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec
