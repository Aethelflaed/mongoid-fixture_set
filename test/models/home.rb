class Home
  include Mongoid::Document

  field :name

  embeds_one :address, as: :place
end

