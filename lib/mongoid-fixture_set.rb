require 'mongoid/fixture_set'

module Mongoid
  module Document
    attr_accessor :__fixture_name
  end
end

