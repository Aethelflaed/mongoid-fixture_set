class FixturesTest < BaseTest
  include Mongoid::FixtureSet::TestHelper
  self.fixture_path = 'test/fixtures'

  def test_should_access_fixtures
    begin
      geoffroy = users(:geoffroy)
      assert true
    rescue
      assert false, 'An exception was thrown'
    end
  end
end


