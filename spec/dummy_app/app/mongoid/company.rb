class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :employees, class_name: 'Person', autosave: true
end
