class GamificationPlugin < Noosfero::Plugin

  def self.plugin_name
    "Gamification Plugin"
  end

  def self.plugin_description
    _("Gamification Plugin")
  end

  def user_data_extras
    proc do
      {:points => current_person.points}
    end
  end

  # Override initial rules with environment specific rules
  def self.gamification_set_rules(environment)
    Merit::AppPointRules.clear
    Merit::AppBadgeRules.clear
    Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
    Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)
  end

  def application_controller_filters
    [{
      :type => 'before_filter', :method_name => 'gamification_set_rules',
      :options => {}, :block => proc { GamificationPlugin.gamification_set_rules(environment) }
    }]
  end

  def body_ending
    proc do
      if current_person.present?
        badges = current_person.badges.notification_pending.all
        current_person.sash.notify_all_badges_from_user
        render :file => 'gamification/display_notifications', :locals => {:badges => badges}
      else
        ''
      end
    end
  end

  def stylesheet?
    true
  end

  def js_files
    ['jquery.noty.packaged.min.js', 'main.js']
  end

  ActionDispatch::Reloader.to_prepare do
    Merit.setup do |config|
      config.checks_on_each_request = false
      config.user_model_name = 'Profile'
      config.current_user_method = 'current_person'
    end

    require_dependency 'merit_ext'
  end

end
