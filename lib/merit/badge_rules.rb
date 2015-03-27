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

    def initialize

      grant_on 'comment#create', badge: 'commenter' do |comment|
        comment.author.present? && comment.author.comments.count >= 5
      end

      grant_on 'article#create', badge: 'article-creator', level: 1 do |article|
        article.author.present? && article.author.articles.count >= 5
      end

      grant_on 'article#create', badge: 'article-creator', level: 2 do |article|
        article.author.present? && article.author.articles.count >= 10
      end

      grant_on 'vote_plugin_profile#vote', badge: 'relevant-commenter', model_name: 'comment', to: 'author' do |voteable|
        return false if voteable.nil? || !voteable.kind_of?(Comment)
        voteable.votes.count >= 2
      end

    end
  end
end
