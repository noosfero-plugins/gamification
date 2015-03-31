# +grant_on+ accepts:
# * Nothing (always grants)
# * A block which evaluates to boolean (recieves the object as parameter)
# * A block with a hash composed of methods to run on the target object with
#   expected values (+votes: 5+ for instance).
#
module Merit
  class BadgeRules
    include Merit::BadgeRulesMethods

    AVAILABLE_RULES = {
      :comment_author => {
        :action => 'comment#create',
        :default_threshold => 5,
        :to => :author,
        :value => lambda { |comment| comment.author.present? ? comment.author.comments.count : 0 }
      },
      :article_author => {
        :action => 'article#create',
        :default_threshold => 5,
        :to => :author,
        :value => lambda { |article| article.author.present? ? article.author.articles.count : 0 }
      },
      :relevant_commenter => {
        :action => 'vote_plugin_profile#vote',
        :default_threshold => 5,
        :value => lambda { |voteable| voteable.kind_of?(Comment) ? voteable.votes.count : 0 }
      }
    }

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      environment.gamification_plugin_badges.all.each do |badge|
        setting = AVAILABLE_RULES[badge.name.to_sym]
        grant_on setting[:action], :badge => badge.name, :level => badge.level, :to => setting[:to] do |source|
          setting[:value].call(source) >= (badge.custom_fields || {}).fetch(:threshold, setting[:default_threshold])
        end
      end
    end

  end
end
