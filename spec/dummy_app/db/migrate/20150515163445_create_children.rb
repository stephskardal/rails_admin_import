class CreateChildren < ActiveRecord::Migration[5.0]
  def change
    create_table :children do |t|
      t.string :name
      t.integer :parent_id

      t.timestamps null: false
    end
  end
end
