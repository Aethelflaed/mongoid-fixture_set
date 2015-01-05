require 'mongoid/fixture_set/fixture'
require 'mongoid/fixture_set/file'
require 'mongoid/fixture_set/class_cache'
require 'mongoid/fixture_set/test_helper'

module Mongoid
  class FixtureSet
    @@cached_fixtures = Hash.new

    cattr_accessor :all_loaded_fixtures
    self.all_loaded_fixtures = {}

    class << self
      def context_class
        @context_class ||= Class.new
      end

      def cached_fixtures(keys_to_fetch = nil)
        if keys_to_fetch
          @@cached_fixtures.values_at(*keys_to_fetch)
        else
          @@cached_fixtures.values
        end
      end

      def reset_cache
        @@cached_fixtures.clear
      end

      def cache_empty?
        @@cached_fixtures.empty?
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
          fs.collection_documents.each do |model, documents|
            model = class_names[model]
            if model
              documents.each do |attributes|
                create_or_update_document(model, attributes)
              end
            end
          end
        end

        cache_fixtures(fixtures_map)

        return cached_fixtures(fixture_set_names)
      end

      def create_or_update_document(model, attributes)
        model = model.constantize if model.is_a? String

        document = find_or_create_document(model, attributes['__fixture_name'])
        update_document(document, attributes)
      end

      def update_document(document, attributes)
        attributes.delete('_id') if document.attributes.has_key?('_id')

        keys = (attributes.keys + document.attributes.keys).uniq
        keys.each do |key|
          if attributes[key].is_a?(Array) || document[key].is_a?(Array)
            document[key] = Array(attributes[key]) + Array(document[key])
          else
            document[key] = attributes[key] || document[key]
          end
        end
        sanitize_new_embedded_documents(document)
        document.save(validate: false)
        return document
      end

      def sanitize_new_embedded_documents(document, is_new = false)
        document.relations.each do |name, relation|
          case relation.macro
          when :embeds_one
            if (document.changes[name] && !document.changes[name][1].nil?) ||
              is_new && document[name]

              embedded_document_set_default_values(document.public_send(relation.name), document[name])
            end
          when :embeds_many
            if (document.changes[name] && !document.changes[name][1].nil?) ||
              is_new && document[name]

              embeddeds = document.public_send(relation.name)
              embeddeds.each_with_index do |embedded, i|
                embedded_document_set_default_values(embedded, document[name][i])
              end
            end
          end
        end
      end

      def embedded_document_set_default_values(document, attributes)
        sanitize_new_embedded_documents(document, true)
        attributes.delete('_id')
        document.fields.select do |k, v|
          k != '_id' && v.default_val != nil && attributes[k] == document[k]
        end.each do |k, v|
          attributes.delete(k)
        end
      end

      def find_or_create_document(model, fixture_name)
        model = model.constantize if model.is_a? String

        document = model.where('__fixture_name' => fixture_name).first
        if document.nil?
          document = model.new
          document['__fixture_name'] = fixture_name
          document.save(validate: false)
        end
        return document
      end
    end

    attr_reader :name, :path, :model_class, :class_name
    attr_reader :fixtures

    def initialize(name, class_name, path)
      @name = name
      @path = path

      if class_name.is_a?(Class)
        @model_class = class_name
      elsif class_name
        @model_class = class_name.safe_constantize
      end

      @class_name = @model_class.respond_to?(:name) ?
        @model_class.name :
        self.class.default_fixture_model_name(name)

      @fixtures = read_fixture_files
    end

    def [](x)
      fixtures[x]
    end

    # Returns a hash of documents to be inserted. The key is the model class, the value is
    # a list of documents to insert in th relative collection.
    def collection_documents
      # allow a standard key to be used for doing defaults in YAML
      fixtures.delete('DEFAULTS')

      # track any join collection we need to insert later
      documents = Hash.new

      documents[class_name] = fixtures.map do |label, fixture|
        attributes = fixture.to_hash

        attributes['__fixture_name'] = label

        next attributes if model_class.nil?

        if !attributes.has_key?('_id')
          document = self.class.find_or_create_document(model_class, label)
          attributes['_id'] = document.id
        end

        set_attributes_timestamps(attributes, model_class)
        
        # interpolate the fixture label
        attributes.each do |key, value|
          attributes[key] = value.gsub("$LABEL", label) if value.is_a?(String)
        end

        model_class.relations.each do |name, relation|
          case relation.macro
          when :belongs_to
            if value = attributes.delete(relation.name.to_s)
              if relation.polymorphic? && value.sub!(/\s*\(([^)]*)\)\s*/, '')
                type = $1
                attributes[relation.foreign_key.sub(/_id$/, '_type')] = type
                attributes[relation.foreign_key] = self.class.find_or_create_document(type, value).id
              else
                attributes[relation.foreign_key] = self.class.find_or_create_document(relation.class_name, value).id
              end
            end
          when :has_many
            if values = attributes.delete(relation.name.to_s)
              values.each do |value|
                document = self.class.find_or_create_document(relation.class_name, value)
                if relation.polymorphic?
                  self.class.update_document(document, {
                    "#{relation.as}_id" => attributes['_id'],
                    "#{relation.as}_type" => model_class.name,
                  })
                else
                  self.class.update_document(document, {
                    relation.foreign_key => attributes['_id']
                  })
                end
              end
            end
          when :has_and_belongs_to_many
            if values = attributes.delete(relation.name.to_s)
              key = "#{relation.name.to_s.singularize}_ids"
              attributes[key] = []

              values.each do |value|
                document = self.class.find_or_create_document(relation.class_name, value)
                attributes[key] << document.id

                self.class.update_document(document, {
                  relation.inverse_foreign_key => Array(attributes['_id'])
                })
              end
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
        attributes['created_at'] = now  unless attributes.has_key?('created_at')
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

