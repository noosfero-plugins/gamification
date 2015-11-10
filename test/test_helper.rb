require_relative "../../../test/test_helper"

def create_point_rule_definition(rule_name, profile = nil, config = {})
  rule = load_point_rule(rule_name, config)
  point_type = GamificationPlugin::PointsType.find_by_name rule_name
  point_type = GamificationPlugin::PointsType.create name: rule_name, description: rule['description'] if point_type.nil?
  categorization = GamificationPlugin::PointsCategorization.create point_type_id: point_type.id, profile: profile, weight: rule[:default_weight]
  GamificationPlugin.gamification_set_rules(@environment)
  categorization
end

def create_all_point_rules
  Merit::PointRules::AVAILABLE_RULES.map do |rule, config|
    create_point_rule_definition(rule)
  end
end

def default_point_weight(rule_name)
  Merit::PointRules::AVAILABLE_RULES[rule_name][:default_weight]
end

def load_point_rule(rule_name, config)
  rule_config = Merit::PointRules::AVAILABLE_RULES[rule_name.to_sym]
  raise "Point rule '#{rule_name}' is not available" if rule_config.nil?
  rule_config.merge!(config)
  rule_config
end

#person_points_debug(person)
def person_points_debug(person)
  person.score_points.map do |sp|
    puts 'Ponto:'
    puts sp.inspect
    puts sp.action.inspect
    puts sp.score.inspect
    puts GamificationPlugin::PointsCategorization.find(sp.score.category).inspect
    puts GamificationPlugin::PointsCategorization.find(sp.score.category).point_type.inspect
  end
end

