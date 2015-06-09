class Blog::Post
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :body, type: String

  has_many :comments, class_name: 'Blog::Comment', autosave: true
  has_and_belongs_to_many :authors, class_name: 'Blog::Author', autosave: true
end
