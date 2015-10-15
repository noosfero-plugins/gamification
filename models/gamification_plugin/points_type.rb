class GamificationPlugin::PointsType < Noosfero::Plugin::ActiveRecord
  attr_accessible :description, :name

  validates :name, presence: true, uniqueness: true

end
