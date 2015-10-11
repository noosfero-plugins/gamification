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
      comment_author: [
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        }
      ],
      comment_received: [
        {
          action: 'comment#create',
          default_threshold: 5,
          to: lambda {|comment| comment.source.author},
          value: lambda { |comment, author| author.present? ? Comment.where(source_id: Article.where(author_id: author.id)).count : 0 }
        }
      ],
      article_author: [
        {
          action: 'article#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |article, author| author.present? ? TextArticle.where(author_id: author.id).count : 0 }
        },
      ],
      positive_votes_received: [
          {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voteable.author},
          value: lambda { |vote, author| Vote.for_voteable(vote.voteable).where('vote > 0').count }
        }
      ],
      negative_votes_received: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voteable.author},
          value: lambda { |vote, author| Vote.for_voteable(vote.voteable).where('vote < 0').count }
        }
      ],
      votes_performed: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voter},
          value: lambda { |vote, voter| Vote.for_voter(voter).count }
        }
      ],
      friendly: [
        {
          action: 'friendship#create',
          default_threshold: 5,
          to: lambda {|friendship| friendship.person},
          value: lambda { |friendship, person| person.friends.count }
        }
      ],
      creative: [
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        },
        {
          action: 'article#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |article, author| author.present? ? author.articles.count : 0 }
        },
      ],
      observer: [
        {
          action: 'article_follower#create',
          default_threshold: 5,
          to: lambda {|article| article.person },
          value: lambda { |article, person| person.present? ? person.article_followers.count : 0 }
        }
      ],
      mobilizer: [
        {
          action: 'Vote#create',
          default_threshold: 5,
          to: lambda { |vote| vote.voter },
          value: lambda { |vote, voter| Vote.for_voter(voter).count }
        },
        {
          action: 'Event#create',
          default_threshold: 5,
          to: lambda { |article| article.author },
          value: lambda { |event, author| author.events.count }
        },
      ],
      generous: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voter},
          value: lambda { |vote, voter| voter.votes.where('vote > 0').count }
        },
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        }
      ],
      articulator: [
        {
          action: 'article_follower#create',
          default_threshold: 5,
          to: :person,
          value: lambda { |article_follower, person| person.present? ? person.article_followers.count : 0 }
        },
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        },
        #mobilizer#create
      ]
    }

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      rules = AVAILABLE_RULES
      rules.merge! CONFERENCE_RULES if defined? CONFERENCE_RULES

      environment.gamification_plugin_badges.all.each do |badge|
        next if rules[badge.name.to_sym].nil?
        rules[badge.name.to_sym].each do |setting|
          grant_on setting[:action], badge: badge.name, level: badge.level, to: setting[:to] do |source|
            can_be_granted = true
            rules[badge.name.to_sym].each do |s|
              if setting[:to].is_a? Symbol
                to = source.send(setting[:to])
              else
                begin
                  to = setting[:to].call(source)
                rescue
                  to = nil
                end
              end
                # pass source and to for different situations
              action = (badge.custom_fields || {}).fetch(s[:action], {})
              can_be_granted &= s[:value].call(source, to) >= action.fetch(:threshold, s[:default_threshold]).to_i
            end
            can_be_granted
          end
        end
      end
    end

  end
end
