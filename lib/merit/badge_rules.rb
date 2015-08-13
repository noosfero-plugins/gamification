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
      :comment_received => {
        :action => 'comment#create',
        :default_threshold => 5,
        :to => lambda {|comment| comment.source.author},
        :value => lambda { |comment| comment.source.author.present? ? Comment.where(:source_id => Article.where(:author_id => comment.source.author.id)).count : 0 }
      },
      :article_author => {
        :action => 'article#create',
        :default_threshold => 5,
        :to => :author,
        :value => lambda { |article| article.author.present? ? article.environment.articles.text_articles.where(:author_id => article.author.id).count : 0 }
      },
      :positive_votes_received => {
        :action => 'vote#create',
        :default_threshold => 5,
        :to => lambda {|vote| vote.voteable.author},
        :value => lambda { |vote| Vote.for_voteable(vote.voteable).where('vote > 0').count }
      },
      :negative_votes_received => {
        :action => 'vote#create',
        :default_threshold => 5,
        :to => lambda {|vote| vote.voteable.author},
        :value => lambda { |vote| Vote.for_voteable(vote.voteable).where('vote < 0').count }
      },
      :votes_performed => {
        :action => 'vote#create',
        :default_threshold => 5,
        :to => lambda {|vote| vote.voter},
        :value => lambda { |vote| Vote.for_voter(vote.voter).count }
      },
      :friendly => {
        :action => 'friendship#create',
        :default_threshold => 5,
        :to => lambda {|friendship| friendship.person},
        :value => lambda { |friendship| friendship.person.friends.count }
      }
    }

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      environment.gamification_plugin_badges.all.each do |badge|
        setting = AVAILABLE_RULES[badge.name.to_sym]
        grant_on setting[:action], :badge => badge.name, :level => badge.level, :to => setting[:to] do |source|
          setting[:value].call(source) >= (badge.custom_fields || {}).fetch(:threshold, setting[:default_threshold]).to_i
        end
      end
    end

  end
end
