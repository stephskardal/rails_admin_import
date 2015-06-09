class Company < ActiveRecord::Base
  has_many :employees, class_name: 'Person', foreign_key: 'employer_id'

  def before_import_save(record)
    self.source = "import"
  end
end
