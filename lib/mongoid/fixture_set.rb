require 'mongoid/fixture_set/fixture'
require 'mongoid/fixture_set/file'

module Mongoid
  class FixtureSet
    class << self
      def context_class
        @context_class ||= Class.new
      end
    end

    attr_reader :name, :path, :model_class, :collection_name
    attr_reader :fixtures

    def initialize(name, class_name, path)
      @name = name
      @path = path

      if class_name.is_a?(Class)
        @model_class = class_name
      elsif class_name
        @model_class = class_name.safe_constantize
      end

      @collection_name = @model_class.collection_name

      @fixtures = read_fixture_files
    end

    def [](x)
      fixtures[x]
    end

    def []=(k,v)
      fixtures[k] = v
    end

    private
    def read_fixture_files
      yaml_files = Dir["#{path}/{**,*}/*.yml"].select { |f|
        ::File.file?(f)
      } + ["#{path}.yml"]

      yaml_files.each_with_object({}) do |file, fixtures|
        Mongoid::FixtureSet::File.open(file) do |fh|
          fh.each do |fixture_name, row|
            fixtures[fixture_name] = Mongoid::FixtureSet::Fixture.new(fixture_name, row, model_class)
          end
        end
      end
    end
  end
end

