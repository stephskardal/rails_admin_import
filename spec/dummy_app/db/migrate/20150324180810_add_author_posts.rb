class AddAuthorPosts < ActiveRecord::Migration[5.0]
  def change
    create_table :blog_authors_posts do |t|
      t.integer :blog_author_id
      t.integer :blog_post_id
    end
  end
end
