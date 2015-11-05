require_dependency 'environment'

class Environment

  has_many :gamification_plugin_environment_badges, :class_name => 'GamificationPlugin::Badge', :foreign_key => 'owner_id', :source => :owner
  has_many :gamification_plugin_organization_badges, :through => :organizations

  def gamification_plugin_badges
    GamificationPlugin::Badge.from("#{gamification_plugin_organization_badges.union(gamification_plugin_environment_badges).to_sql} as #{GamificationPlugin::Badge.table_name}")
  end

end
