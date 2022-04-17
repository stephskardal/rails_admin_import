class Ball
  include Mongoid::Document
  include Mongoid::Timestamps

  field :color, type: String
  validates :color, presence: true, exclusion: %w(forbidden)

  def before_import_attributes(record)
    record[:color] = "gray" if record[:color] == "grey"
  end
end
