require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'

begin
  require "#{CI_ORM}"
  require "#{CI_ORM}/railtie"
rescue LoadError # rubocop:disable HandleExceptions
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups, CI_ORM)

module DummyApp
  class Application < Rails::Application
    # Configure for rails 6.1
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.eager_load_paths.reject! { |p| p =~ %r{/app/(\w+)$} && !%w(controllers helpers views).push(CI_ORM).include?(Regexp.last_match[1]) }
    config.eager_load_paths += %W(#{config.root}/app/#{CI_ORM} #{config.root}/app/#{CI_ORM}/concerns)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
  end
end

