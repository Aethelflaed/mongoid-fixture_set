require 'active_support/concern'

module Mongoid
  class FixtureSet
    module TestHelper
      extend ActiveSupport::Concern

      def before_setup
        setup_fixtures
        super
      end

      def after_teardown
        super
        teardown_fixtures
      end

      included do
        class_attribute :fixture_path, :instance_writer => false
        class_attribute :fixture_set_names
        class_attribute :load_fixtures_once
        class_attribute :cached_fixtures

        self.fixture_set_names = []
        self.load_fixtures_once = false
        self.cached_fixtures = nil
      end

      module ClassMethods
       def fixtures(*fixture_set_names)
         if fixture_set_names.first == :all
           fixture_set_names = Dir["#{fixture_path}/{**,*}/*.{yml}"]
           fixture_set_names.map! { |f| f[(fixture_path.to_s.size + 1)..-5] }
         else
           fixture_set_names = fixture_set_names.flatten.map(&:to_s)
         end
         self.fixture_set_names |= fixture_set_names
         setup_fixture_accessors(fixture_set_names)
       end

       def setup_fixture_accessors(fixture_set_names = nil)
         fixture_set_names = Array(fixture_set_names || self.fixture_set_names)
         methods = Module.new do
           fixture_set_names.each do |fs_name|
             fs_name = fs_name.to_s
             accessor_name = fs_name.tr('/', '_').to_sym
             define_method(accessor_name) do |*fixture_names|
               force_reload = fixture_names.pop if fixture_names.last == true || fixture_names.last == :reload
               @fixture_cache[fs_name] ||= {}
               instances = fixture_names.map do |f_name|
                 f_name = f_name.to_s
                 @fixture_cache[fs_name].delete(f_name) if force_reload
                 if @loaded_fixtures[fs_name] && @loaded_fixtures[fs_name][f_name]
                   @fixture_cache[fs_name][f_name] ||= @loaded_fixtures[fs_name][f_name].find
                 else
                   raise FixtureNotFound, "No fixture named '#{f_name}' found for fixture set '#{fs_name}'"
                 end
               end
               instances.size == 1 ? instances.first : instances
             end
           end
         end
         include methods
       end
      end

      def setup_fixtures
        @fixture_cache = {}

        if self.class.cached_fixtures && self.class.load_fixtures_once
          self.class.fixtures(self.class.fixture_set_names)
          @loaded_fixtures = self.class.cached_fixtures
        else
          Mongoid::FixtureSet.reset_cache
          self.loaded_fixtures = load_fixtures
          self.class.cached_fixtures = @loaded_fixtures
        end
      end

      def teardown_fixtures
        Mongoid::FixtureSet.reset_cache
      end

      private
      def load_fixtures
        fixture_set_names = self.class.fixture_set_names
        if fixture_set_names.empty?
          self.class.fixtures(:all)
          fixture_set_names = self.class.fixture_set_names
        end
        fixtures = Mongoid::FixtureSet.create_fixtures(fixture_path, fixture_set_names)
      end

      def loaded_fixtures=(fixtures)
        @loaded_fixtures = Hash[fixtures.dup.map { |f| [f.name, f] }]
      end
    end
  end
end

