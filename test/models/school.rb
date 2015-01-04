class School
  include Mongoid::Document

  field :name

  has_many :groups, as: :something
end

