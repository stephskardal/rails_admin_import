#!/usr/bin/env rake

require 'bundler'
Bundler::GemHelper.install_tasks

# Piggyback off the Rails Admin rake tasks to set up the CI environment
spec = Gem::Specification.find_by_name 'rails_admin'
Dir["#{spec.gem_dir}/lib/tasks/*.rake"].each { |rake| load rake }

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task test: :spec

task default: :spec
