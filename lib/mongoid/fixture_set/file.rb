require 'erb'
require 'yaml'

module Mongoid
  class FixtureSet

    class RenderContext
      def self.create_subclass
        Class.new Mongoid::FixtureSet.context_class do
          def get_binding
            binding()
          end
        end
      end
    end

    class Mongoid::FixtureSet::File # :nodoc:
      include Enumerable

      def self.open(file)
        x = new file
        block_given? ? yield(x) : x
      end

      def initialize(file)
        @file = file
        @rows = nil
      end

      def each(&block)
        rows.each(&block)
      end

      private
      def rows
        return @rows if @rows
        begin
          data = YAML.load(render(IO.read(@file)))
        rescue ArgumentError, Psych::SyntaxError => error
          raise FormatError, "a YAML error occurred parsing #{@file}. Please note that YAML must be consistently indented using spaces. Tabs are not allowed. Please have a look at http://www.yaml.org/faq.html\nThe exact error was:\n #{error.class}: #{error}", error.backtrace
        end
        @rows = data ? validate(data).to_a : []
      end

      def render(content)
        context = RenderContext.create_subclass.new
        ERB.new(content).result(context.get_binding)
      end

      # Validate our unmarshalled data.
      def validate(data)
        unless Hash === data || YAML::Omap === data
          raise FormatError, 'fixture is not a hash'
        end
        raise FormatError unless data.all? { |name, row| Hash === row }
        data
      end
    end
  end
end

