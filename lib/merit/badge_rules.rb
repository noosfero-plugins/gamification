# Be sure to restart your server when you modify this file.
#
# +grant_on+ accepts:
# * Nothing (always grants)
# * A block which evaluates to boolean (recieves the object as parameter)
# * A block with a hash composed of methods to run on the target object with
#   expected values (+votes: 5+ for instance).
#
# +grant_on+ can have a +:to+ method name, which called over the target object
# should retrieve the object to badge (could be +:user+, +:self+, +:follower+,
# etc). If it's not defined merit will apply the badge to the user who
# triggered the action (:action_user by default). If it's :itself, it badges
# the created object (new user for instance).
#
# The :temporary option indicates that if the condition doesn't hold but the
# badge is granted, then it's removed. It's false by default (badges are kept
# forever).

module Merit
  class BadgeRules
    include Merit::BadgeRulesMethods

    AVAILABLE_RULES = {
      :comment_author => {
        :action => 'comment#create',
        :default_threshold => 5,
        :value => lambda { |comment| comment.author.present? ? comment.author.comments.count : 0 }
      },
      :article_author => {
        :action => 'article#create',
        :default_threshold => 5,
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
        grant_on setting[:action], :badge => badge.name, :level => badge.level do |source|
          setting[:value].call(source) >= (badge.custom_fields || {}).fetch(:threshold, setting[:default_threshold])
        end
      end

      grant_on 'vote_plugin_profile#vote', badge: 'relevant-commenter', model_name: 'comment', to: 'author' do |voteable|
        return false if voteable.nil? || !voteable.kind_of?(Comment)
        voteable.votes.count >= 2
      end

    end
  end
end
