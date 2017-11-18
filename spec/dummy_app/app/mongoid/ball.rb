class Ball
  include Mongoid::Document
  include Mongoid::Timestamps

  field :color, type: String
  validates :color, presence: true, exclusion: %w(forbidden)
end
