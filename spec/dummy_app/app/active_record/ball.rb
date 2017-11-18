class Ball < ActiveRecord::Base
  validates :color, presence: true, exclusion: %w(forbidden)
end
