module Merit

  class Sash
    has_many :gamification_plugin_badges, :through => :badges_sashes, :source => :gamification_plugin_badge
    alias :badges :gamification_plugin_badges
    has_one :profile, :foreign_key => :sash_id, :class_name => 'Profile'
    has_one :article, :foreign_key => :sash_id, :class_name => 'Article'

    def target
      profile || article
    end
  end

  def notify_all_badges_from_user
    badges_sashes.update_all(:notified_user => true)
  end

end
