$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sfdc_bulk/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sfdc_bulk"
  s.version     = SfdcBulk::VERSION
  s.authors     = ["Olivier Gosse-Gardet"]
  s.email       = ["olivier.gosse.gardet@gmail.com"]
  s.homepage    = "http://home"
  s.summary     = "SFDC BULK API mapper"
  s.description = "Description of SfdcBulk."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "> 4.2"
  s.add_dependency "savon", "~> 2.11.1"

  s.add_dependency "rest-client"
  s.add_dependency "activerecord-import"
  # s.add_development_dependency "sqlite3"
end
