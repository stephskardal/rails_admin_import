class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  has_many :employees, class_name: 'Person', autosave: true

  field :source, type: String, default: "web"

  def before_import_save(record)
    self.source = "import"
  end
end
