class AddSourceToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :source, :string, :default => "web"
  end
end
