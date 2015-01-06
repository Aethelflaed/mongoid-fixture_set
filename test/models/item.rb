class Item
  include Mongoid::Document

  belongs_to :user

  field :name
end

