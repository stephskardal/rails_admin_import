class Child
  include Mongoid::Document
  field :name, type: String
  belongs_to :parent_id
end
