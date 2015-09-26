require_relative "../../../test/test_helper"

def create_merit_categorization
  c = fast_create(Community)
  Merit::PointRules::AVAILABLE_RULES.each do |name, setting|
    point_type = GamificationPlugin::PointsType.find_by_name name
    point_type = GamificationPlugin::PointsType.create name: name, description: setting['description'] if point_type.nil?
    profile = setting.fetch(:profile_action, true) ? c : nil
    GamificationPlugin::PointsCategorization.create! point_type_id: point_type.id, profile: profile, weight: setting[:default_weight]
  end
  c
end#
