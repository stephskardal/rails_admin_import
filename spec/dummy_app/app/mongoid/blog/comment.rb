class Blog::Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :author, type: String
  field :text, type: String
  belongs_to :post, class_name: 'Blog::Post', optional: true
end
