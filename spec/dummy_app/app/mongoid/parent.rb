class Parent
  include Mongoid::Document
  has_many :children
end
