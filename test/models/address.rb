class Address
  include Mongoid::Document

  embedded_in :place, polymorphic: true

  field :city
end

