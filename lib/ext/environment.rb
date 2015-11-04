require_dependency 'environment'

class Environment

  has_many :gamification_plugin_badges, :class_name => 'GamificationPlugin::Badge', :foreign_key => 'owner_id', :source => :owner
  has_many :gamification_plugin_organization_badges, :through => :organizations

end
