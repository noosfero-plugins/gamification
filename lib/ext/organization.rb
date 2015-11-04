require_dependency 'organization'

class Organization

  has_many :gamification_plugin_organization_badges, :class_name => 'GamificationPlugin::Badge', :foreign_key => 'owner_id', :source => :owner

end
