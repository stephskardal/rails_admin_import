class Blog::Post < ActiveRecord::Base
  self.table_name = "blog_posts"

  has_many :comments, class_name: 'Blog::Comment',
    foreign_key: 'blog_post_id'

  has_and_belongs_to_many :authors, class_name: 'Blog::Author',
    foreign_key: 'blog_post_id', association_foreign_key: 'blog_author_id'
end
