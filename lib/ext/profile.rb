require_dependency 'profile'

class Profile

  has_merit

  def gamification_plugin_calculate_level
    settings = GamificationPlugin.settings(environment)
    last_level = 0
    (settings.get_setting(:rank_rules) || []).sort_by {|r| r[:points] }.each do |rule|
      return last_level if points < rule[:points]
      last_level = rule[:level]
    end
    last_level
  end

end
