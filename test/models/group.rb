class Group
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short

  field :name

  has_many :main_users, class_name: 'User', inverse_of: :main_group

  has_and_belongs_to_many :users

  belongs_to :something, polymorphic: true
end

