require 'rake/testtask'

#Rake::TestTask.new do |test|
#  test.pattern = 'test/**/*_test.rb'
#  test.libs << 'test'
#end

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "rails_admin_import"
    gem.summary = "Import functionality for rails admin"
    gem.email = "steph@endpoint.com"
    gem.authors = ["Steph Skardal"]
    gem.files = Dir["{lib}/**/*", "{app}/**/*", "{public}/**/*", "{config}/**/*"]
  end
  Jeweler::GemcutterTasks.new
rescue
  puts "Jeweler or dependency not available."
end
