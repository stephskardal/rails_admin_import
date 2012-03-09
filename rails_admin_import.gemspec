$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_admin_import/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_admin_import"
  s.version     = RailsAdminImport::VERSION
  s.authors     = ["Steph Skardal"]
  s.email       = ["steph@endpoint.com"]
  s.homepage    = "http://www.endpoint.com/"
  s.summary     = "Generic import solution for RailsAdmin."
  s.description = "Generic import solution for RailsAdmin."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
end
