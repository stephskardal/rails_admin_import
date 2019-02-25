class Child < ActiveRecord::Base
  belongs_to :parent, optional: true
end
