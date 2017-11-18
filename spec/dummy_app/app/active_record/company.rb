class Company < ActiveRecord::Base
  has_many :employees, class_name: 'Person', foreign_key: 'employer_id'

  def self.before_import_find(record)
    throw :skip if record[:name] == "skip"
  end

  def before_import_attributes(record)
    record.delete(:employees) if record[:name] == "No employees"
  end

  def before_import_save(record)
    self.source = "import"
  end

  # Global hooks
  def self.callback_log
    @@callbacks
  end
  def self.reset_callback_log
    @@callbacks = []
  end
  def self.before_import
    @@callbacks << :before_import
  end
  def self.after_import
    @@callbacks << :after_import
  end
end
