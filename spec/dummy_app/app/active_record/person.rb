class Person < ActiveRecord::Base
  belongs_to :employer, class_name: 'Company', optional: true

  def full_name
    [first_name, last_name].compact.join ' '
  end

  def full_name=(name)
    first_name, last_name = name.split
    self.first_name = first_name
    self.last_name = last_name
  end
end
