class CreateBlogComments < ActiveRecord::Migration[5.0]
  def change
    create_table :blog_comments do |t|
      t.string :author
      t.string :text
      t.integer :blog_post_id

      t.timestamps null: false
    end
  end
end
