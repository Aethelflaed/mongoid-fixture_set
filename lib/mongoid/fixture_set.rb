require 'mongoid/fixture_set/fixture'
require 'mongoid/fixture_set/file'
require 'mongoid/fixture_set/class_cache'

require 'active_support/core_ext/digest/uuid'

module Mongoid
  class FixtureSet
    @@cached_fixtures = Hash.new

    cattr_accessor :all_loaded_fixtures
    self.all_loaded_fixtures = {}

    class << self
      def context_class
        @context_class ||= Class.new
      end

      def cached_fixtures(*keys_to_fetch)
        if keys_to_fetch.empty?
          @@cached_fixtures.values
        else
          @@cached_fixtures.values_at(*keys_to_fetch)
        end
      end

      def reset_cache
        @@cached_fixtures.clear
      end

      def fixture_is_cached?(name)
        @@cached_fixtures[name]
      end

      def cache_fixtures(fixtures_map)
        @@cached_fixtures.update(fixtures_map)
      end

      def default_fixture_model_name(fixture_set_name)
        fixture_set_name.singularize.camelize
      end

      def update_all_loaded_fixtures(fixtures_map)
        all_loaded_fixtures.update(fixtures_map)
      end

      def create_fixtures(fixtures_directory, fixture_set_names, class_names = {})
        fixture_set_names = Array(fixture_set_names).map(&:to_s)
        class_names = ClassCache.new(class_names)

        files_to_read = fixture_set_names.reject { |fs_name|
          fixture_is_cached?(fs_name)
        }

        if files_to_read.empty?
          return cached_fixtures(fixture_set_names)
        end

        fixtures_map = {}
        fixture_sets = files_to_read.map do |fs_name|
          klass = class_names[fs_name]
          fixtures_map[fs_name] = Mongoid::FixtureSet.new(
                                      fs_name,
                                      klass,
                                      ::File.join(fixtures_directory, fs_name))
        end

        update_all_loaded_fixtures fixtures_map

        fixture_sets.each do |fs|
          collection_documents = fs.collection_documents
          collection_documents.each_key do |model|
            model.delete_all
          end
          collection_documents.each do |model, documents|
            documents.each do |attributes|
              document = model.new
              document.attributes.update(attributes)
              document.save
            end
          end
        end

        cache_fixtures(fixtures_map)

        return cached_fixtures(fixture_set_names)
      end

      # Returns a consistent, platform-independent identifier for +label+.
      # Integer identifiers are values less than 2^30. UUIDs are RFC 4122 version 5 SHA-1 hashes.
      def identify(label)
        Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, label.to_s)
      end
    end

    attr_reader :name, :path, :model_class, :collection_name
    attr_reader :fixtures

    def initialize(name, class_name, path)
      @name = name
      @path = path

      if class_name.is_a?(Class)
        @model_class = class_name
      else
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

    # Returns a hash of documents to be inserted. The key is the model class, the value is
    # a list of documents to insert in th relative collection.
    def collection_documents
      # allow a standard key to be used for doing defaults in YAML
      fixtures.delete('DEFAULTS')

      # track any join collection we need to insert later
      documents = Hash.new { |h, collection| h[collection] = [] }

      documents[model_class] = fixtures.map do |label, fixture|
        attributes = fixture.to_hash
        attributes['__fixture_name'] = fixture.name

        set_attributes_timestamps(attributes, model_class)
        
        # interpolate the fixture label
        attributes.each do |key, value|
          attributes[key] = value.gsub("$LABEL", label) if value.is_a?(String)
        end

        attributes['_id'] = self.class.identify(label)

        # should work as is for STI

        model_class.relations.each do |name, relation|
          case relation.macro
          when :belongs_to
            if value = attributes.delete(relation.name.to_s)
              if relation.polymorphic? && value.sub!(/\s*\(([^)]*)\)\s*/, '')
                attributes["#{relation.name}_type"] = $1
              end
              attributes["#{relation.name}_id"] = self.class.identify(value)
            end
          when :has_and_belongs_to_many
            if values = attributes.delete(relation.name.to_s)
              attributes["#{relation.name.to_s.singularize}_ids"] = values.map{|v| self.class.identify(v)}
              # FIXME: this does not set the other side of the relation
            end
          end
        end

        attributes
      end

      return documents
    end

    private
    def set_attributes_timestamps(attributes, model_class)
      now = Time.now.utc

      if model_class < Mongoid::Timestamps::Created::Short
        attributes['c_at'] = now        unless attributes.has_key?('c_at')
      elsif model_class < Mongoid::Timestamps::Created
        attributes['created_at'] = now  unless attributes.has_key/('created_at')
      end

      if model_class < Mongoid::Timestamps::Updated::Short
        attributes['u_at'] = now        unless attributes.has_key?('u_at')
      elsif model_class < Mongoid::Timestamps::Updated
        attributes['updated_at'] = now  unless attributes.has_key?('updated_at')
      end
    end

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

