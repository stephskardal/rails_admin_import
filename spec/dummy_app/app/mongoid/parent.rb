class Parent
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :children, autosave: true
end
