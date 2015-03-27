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

  Merit.setup do |config|
    config.checks_on_each_request = false
    config.user_model_name = 'Profile'
    config.current_user_method = 'current_person'
  end

  require 'merit_ext'

  Merit::Badge.create!(
    id: 1,
    name: "commenter",
    description: "Commenter"
  )
  Merit::Badge.create!(
    id: 2,
    name: "relevant-commenter",
    description: "Relevant Commenter"
  )
  Merit::Badge.create!(
    id: 3,
    name: "article-creator",
    description: "Article Creator",
    level: 1
  )
  Merit::Badge.create!(
    id: 4,
    name: "article-creator",
    description: "Article Creator",
    level: 2
  )

end
