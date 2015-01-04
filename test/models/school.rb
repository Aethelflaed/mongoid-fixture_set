class School
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :name

  has_many :groups, as: :something
end

