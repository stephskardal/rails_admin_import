class CreateBalls < ActiveRecord::Migration[5.0]
  def change
    create_table :balls do |t|
      t.string :color

      t.timestamps null: false
    end
  end
end
