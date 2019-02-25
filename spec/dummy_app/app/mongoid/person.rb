class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  belongs_to :employer, class_name: "Company", optional: true

  def full_name
    [first_name, last_name].compact.join ' '
  end
end
