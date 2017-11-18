class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :employees, class_name: 'Person', autosave: true

  field :source, type: String, default: "web"

  def self.before_import_find(record)
    throw :skip if record[:name] == "skip"
  end

  def before_import_attributes(record)
    record.delete(:employees) if record[:name] == "No employees"
  end

  def before_import_save(record)
    self.source = "import"
  end
end
