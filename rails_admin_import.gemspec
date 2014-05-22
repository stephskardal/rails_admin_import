$:.push File.expand_path("../lib", __FILE__)

require "rails_admin_import/version"
 
Gem::Specification.new do |s|
  s.name = "rails_admin_import"
  s.version = RailsAdminImport::VERSION
  s.authors = ["Steph Skardal"]
  s.email = "steph@endpoint.com"
  s.files = Dir["{app,config,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md", "RELEASE_NOTES"]
  s.summary = "Import functionality for rails admin"
end
