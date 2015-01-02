require 'test_helper'
require 'pry'

module Mongoid
  class FixtureSetTest < BaseTest
    def test_should_create_fixture_set
      fs = Mongoid::FixtureSet.new('users', 'User', 'test/fixtures/users')
      assert_equal User, fs.model_class
      fixture = fs['geoffroy']
      assert_equal 'Geoffroy', fixture['firstname']
      assert_equal 'Planquart', fixture['lastname']
    end

    def test_should_create_fixtures
      fs = Mongoid::FixtureSet.create_fixtures('test/fixtures/', %w(users groups))
      binding.pry
    end
  end
end

