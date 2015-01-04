require 'bundler/setup'
require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'minitest/autorun'
require 'mongoid'

require File.expand_path("../../lib/mongoid-fixture_set", __FILE__)

Mongoid.load!("#{File.dirname(__FILE__)}/mongoid.yml", "test")

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |f| require f }

class BaseTest < MiniTest::Test
  def teardown
    Mongoid::Sessions.default.use('mongoid_fixture_set_test').drop
  end
end

