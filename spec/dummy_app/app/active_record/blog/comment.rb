class Blog::Comment < ActiveRecord::Base
  self.table_name = "blog_comments"

  belongs_to :post, class_name: 'Blog::Post'
end
