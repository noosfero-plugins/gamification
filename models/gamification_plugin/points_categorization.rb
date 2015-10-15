class GamificationPlugin::PointsCategorization < Noosfero::Plugin::ActiveRecord
  belongs_to :profile
  belongs_to :point_type, class_name: 'GamificationPlugin::PointsType', foreign_key: :point_type_id
  attr_accessible :profile_id, :profile, :point_type_id, :weight

  validates_presence_of :weight
  validates :point_type_id, presence: true, uniqueness: { scope: :profile_id, message: _("should have only one point type per profile") } 
#  validates :point_type_id, presence: true, uniqueness: true

  scope :for_type, lambda { |p_type| joins(:point_type).where(gamification_plugin_points_types: {name: p_type}) }
  scope :for_profile, lambda { |p_profile| joins(:profile).where(profiles: {identifier: p_profile}) }

  scope :grouped_profiles, select(:profile_id).group(:profile_id).includes(:profile)
end
