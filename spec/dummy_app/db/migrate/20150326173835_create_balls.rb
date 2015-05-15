class CreateBalls < ActiveRecord::Migration
  def change
    create_table :balls do |t|
      t.string :color

      t.timestamps null: false
    end
  end
end
