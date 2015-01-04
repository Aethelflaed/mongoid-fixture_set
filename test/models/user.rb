class User
  include Mongoid::Document
  include Mongoid::Timestamps::Updated::Short

  field :firstname
  field :lastname

  belongs_to :main_group, class_name: 'Group', inverse_of: :main_users

  has_and_belongs_to_many :groups
end

