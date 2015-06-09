class Blog::Author < ActiveRecord::Base
  self.table_name = "blog_authors"

  has_and_belongs_to_many :posts, class_name: 'Blog::Post',
    foreign_key: 'blog_author_id', association_foreign_key: 'blog_post_id'
end
