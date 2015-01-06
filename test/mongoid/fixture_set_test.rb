require 'test_helper'
require 'pry'

module Mongoid
  class FixtureSetTest < BaseTest
    def test_should_initialize_fixture_set
      Mongoid::FixtureSet.reset_cache
      fs = Mongoid::FixtureSet.new('users', 'User', 'test/fixtures/users')
      assert_equal User, fs.model_class
      fixture = fs['geoffroy']
      assert_equal 'User', fixture.class_name
      assert_equal 'Geoffroy', fixture['firstname']
      assert_equal 'Planquart', fixture['lastname']
    end

    def test_should_not_create_fixtures
      Mongoid::FixtureSet.reset_cache
      fs = Mongoid::FixtureSet.create_fixtures('test/fixtures/', [])
      assert_equal 0, fs.count
    end

    def test_should_create_not_model_fixture
      Mongoid::FixtureSet.reset_cache
      fs = Mongoid::FixtureSet.create_fixtures('test/fixtures', %w(not_models))
      fs = fs.first
      fixture = fs['error']

      begin
        fixture.find
        assert false, 'No exception has been raised'
      rescue Mongoid::FixtureSet::FixtureClassNotFound
        assert true
      end
    end

    test 'should raised if nested polymorphic relation' do
      Mongoid::FixtureSet.reset_cache

      begin
        fs = Mongoid::FixtureSet.create_fixtures('test/nested_polymorphic_relation_fixtures', %w(groups))
        assert false
      rescue Mongoid::FixtureSet::FixtureError
        assert true
      end
    end

    def test_should_create_fixtures
      Mongoid::FixtureSet.reset_cache
      fs = Mongoid::FixtureSet.create_fixtures('test/fixtures/', %w(users groups schools organisations))

      users = fs.find{|x| x.model_class == User}
      f_geoffroy = users['geoffroy']

      assert_equal 6, School.count
      assert_equal 6, User.count

      geoffroy = User.find_by(firstname: 'Geoffroy')
      user1 = User.find_by(firstname: 'Margot')
      sudoers = Group.find_by(name: 'Sudoers!')
      print = Group.find_by(name: 'Print')
      group1 = Group.find_by(name: 'Margot')
      orga1 = Organisation.find_by(name: '1 Organisation')
      school = School.find_by(name: 'School')
      test_item = Item.find_by(name: 'Test')
      user2 = User.find_by(firstname: 'user2')
      win_group = Group.find_by(name: 'Win?')
      test_nested_polymorphic_belongs_to = Group.find_by(name: 'Test nested polymorphic belongs_to')
      test_nested_has_many_creation = Group.find_by(name: 'Test nested has_many creation')
      User.find_by(firstname: 'Created in nested group')

      assert_equal 1, user1.homes.count
      assert_equal geoffroy, f_geoffroy.find
      assert_equal 3, print.users.count
      assert print.users.include?(geoffroy)
      assert print.users.include?(user1)
      assert sudoers.main_users.include?(geoffroy)
      assert_equal group1, user1.main_group
      assert_equal print, user1.groups.first
      assert_equal geoffroy, test_item.user
      assert win_group.main_users.include?(user2)

      assert_equal 1, school.groups.count
      assert_equal group1, school.groups.first
      assert_equal school, group1.something

      assert_equal 3, orga1.groups.count
      assert orga1.groups.include?(sudoers)
      assert_equal orga1, sudoers.something
    end
  end
end

