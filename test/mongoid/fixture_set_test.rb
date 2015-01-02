require 'test_helper'
require 'pry'

module Mongoid
  class FixtureSetTest < BaseTest
    def test_should_create_fixture_set
      fs = Mongoid::FixtureSet.new('users', 'User', 'test/fixtures/users')
      assert_equal User, fs.model_class
      fixture = fs['geoffroy']
      assert_equal({
        'firstname' => 'Geoffroy',
        'lastname' => 'Planquart',
      }, fixture.fixture)
    end
  end
end

