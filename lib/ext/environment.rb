require_dependency 'environment'

class Environment

  has_many :gamification_plugin_environment_badges, :class_name => 'GamificationPlugin::Badge', :foreign_key => 'owner_id', :source => :owner
  has_many :gamification_plugin_organization_badges, :through => :organizations

  def gamification_plugin_badges
    GamificationPlugin::Badge.joins('inner join profiles on profiles.id = owner_id').where(['owner_id = ? or profiles.environment_id = ?', self.id, self.id])
  end

end
