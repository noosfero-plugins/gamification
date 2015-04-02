module Merit

  class BadgesSash
    belongs_to :gamification_plugin_badge, :class_name => 'GamificationPlugin::Badge', :foreign_key => :badge_id
    alias :badge :gamification_plugin_badge
  end

end
