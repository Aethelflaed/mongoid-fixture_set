class Address
  include Mongoid::Document

  embedded_in :place, polymorphic: true

  field :city
  field :real, type: Boolean, default: true

  belongs_to :organisation
end

