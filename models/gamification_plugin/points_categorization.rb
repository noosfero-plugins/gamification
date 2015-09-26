class GamificationPlugin::PointsCategorization < Noosfero::Plugin::ActiveRecord
  belongs_to :profile
  belongs_to :point_type, class_name: 'GamificationPlugin::PointsType', foreign_key: :point_type_id, dependent: :destroy
  attr_accessible :profile_id, :profile, :point_type_id, :weight

  validates_presence_of :point_type_id, :weight

  scope :by_type, lambda { |p_type| joins(:point_type).where(gamification_plugin_points_types: {name: p_type}) }
  scope :by_profile, lambda { |p_profile| joins(:profile).where(profiles: {identifier: p_profile}) }
end
