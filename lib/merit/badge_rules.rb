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
      :comment_author => [
        {
          :action => 'comment#create',
          :default_threshold => 5,
          :to => :author,
          :value => lambda { |author| author.present? ? author.comments.count : 0 }
        }
      ],
      :comment_received => [
        {
          :action => 'comment#create',
          :default_threshold => 5,
          :to => lambda {|comment| comment.source.author},
          :value => lambda { |author| author.present? ? Comment.where(:source_id => Article.where(:author_id => author.id)).count : 0 }
        }
      ],
      :article_author => [
        {
          :action => 'article#create',
          :default_threshold => 5,
          :to => :author,
          :value => lambda { |author| author.present? ? author.environment.articles.text_articles.where(:author_id => author.id).count : 0 }
        },
      ],
      :positive_votes_received => [
          {
          :action => 'vote#create',
          :default_threshold => 5,
          :to => lambda {|vote| vote.voteable.author},
          :value => lambda { |vote| Vote.for_voteable(vote.voteable).where('vote > 0').count }
        }
      ],
      :negative_votes_received => [
        {
          :action => 'vote#create',
          :default_threshold => 5,
          :to => lambda {|vote| vote.voteable.author},
          :value => lambda { |vote| Vote.for_voteable(vote.voteable).where('vote < 0').count }
        }
      ],
      :votes_performed => [
        {
          :action => 'vote#create',
          :default_threshold => 5,
          :to => lambda {|vote| vote.voter},
          :value => lambda { |vote| Vote.for_voter(vote.voter).count }
        }
      ],
      :friendly => [
        {
          :action => 'friendship#create',
          :default_threshold => 5,
          :to => lambda {|friendship| friendship.person},
          :value => lambda { |person| person.friends.count }
        }
      ],
      :creative => [
        {
          :action => 'comment#create',
          :default_threshold => 5,
          :to => :author,
          :value => lambda { |author| author.present? ? author.comments.count : 0 }
        },
        {
          :action => 'proposal#create',
          :default_threshold => 5,
          :to => :author,
          :value => lambda { |author| author.present? ? author.proposals.count : 0 }
        },
      ]
    }

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      environment.gamification_plugin_badges.all.each do |badge|
        settings = AVAILABLE_RULES[badge.name.to_sym]
        settings.each_with_index do |setting,i|
          grant_on setting[:action], :badge => badge.name, :level => badge.level, :to => setting[:to] do |source|
            can_be_granted = true
            settings.each_with_index do |s,j|
              if s[:to].is_a? Symbol
                receiver = source.send s[:to]
              else
                receiver = s[:to].call source
              end
              can_be_granted &= s[:value].call(receiver) >= (badge.custom_fields || {}).fetch(:threshold, s[:default_threshold]).to_i
            end
          end
        end
      end
    end

  end
end
