class GamificationPlugin::PointsType < Noosfero::Plugin::ActiveRecord
  attr_accessible :description, :name

  validates_presence_of :name
end
