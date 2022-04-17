class Ball < ActiveRecord::Base
  validates :color, presence: true, exclusion: %w(forbidden)

  def before_import_attributes(record)
    record[:color] = "gray" if record[:color] == "grey"
  end
end
