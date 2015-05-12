require_dependency 'profile'

class Profile

  has_merit

  def gamification_plugin_calculate_level
    settings = GamificationPlugin.settings(environment)
    score = self.points
    last_level = 0
    (settings.get_setting(:rank_rules) || []).sort_by {|r| r[:points] }.each_with_index do |rule, i|
      return last_level if score < rule[:points].to_i
      last_level = rule[:level] || i+1
    end
    last_level
  end

end
