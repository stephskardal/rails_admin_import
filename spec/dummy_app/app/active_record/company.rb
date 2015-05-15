class Company < ActiveRecord::Base
  has_many :employees, class_name: 'Person', foreign_key: 'employer_id'
end
