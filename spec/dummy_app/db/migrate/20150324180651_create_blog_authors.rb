class CreateBlogAuthors < ActiveRecord::Migration
  def change
    create_table :blog_authors do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
