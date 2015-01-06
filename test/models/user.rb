class User
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short

  embeds_one :address, as: :place
  embeds_many :homes

  field :firstname
  field :lastname

  field :default, type: Boolean, default: true

  belongs_to :main_group, class_name: 'Group', inverse_of: :main_users

  has_and_belongs_to_many :groups

  has_many :items
  accepts_nested_attributes_for :items
end

