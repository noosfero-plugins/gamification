module Merit

  class Sash
    has_many :gamification_plugin_badges, :through => :badges_sashes, :source => :gamification_plugin_badge
    alias :badges :gamification_plugin_badges
  end

  def notify_all_badges_from_user
    badges_sashes.update_all(:notified_user => true)
  end

end
