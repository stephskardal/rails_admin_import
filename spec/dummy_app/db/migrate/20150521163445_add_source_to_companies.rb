class AddSourceToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :source, :string, :default => "web"
  end
end
