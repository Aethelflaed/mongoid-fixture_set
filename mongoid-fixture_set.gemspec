# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'mongoid/fixture_set/version'

Gem::Specification.new do |s|
  s.license     = 'MIT'
  s.name        = 'mongoid-fixture_set'
  s.version     = Mongoid::FixtureSet::VERSION
  s.authors     = ['Geoffroy Planquart']
  s.email       = ['geoffroy@planquart.fr']
  s.homepage    = 'https://github.com/Aethelflaed/mongoid-fixture_set'
  s.summary     = 'Fixtures for Mongoid'
  s.description = 'Let you use fixtures with Mongoid the same way you did with ActiveRecord'

  s.files       = Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files  = Dir['test/**/*']

  s.add_dependency 'mongoid',       '>= 4.0'
  s.add_dependency 'activesupport', '>= 4.0'
end

