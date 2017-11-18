class CreateBlogAuthors < ActiveRecord::Migration[5.0]
  def change
    create_table :blog_authors do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
