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
          target_profile: lambda {|comment| comment.profile },
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        }
      ],
      comment_received: [
        {
          action: 'comment#create',
          default_threshold: 5,
          to: lambda {|comment| comment.source.author},
          target_profile: lambda {|comment| comment.profile },
          value: lambda { |comment, author| author.present? ? Comment.where(source_id: Article.where(author_id: author.id)).count : 0 }
        }
      ],
      article_author: [
        {
          action: 'article#create',
          default_threshold: 5,
          to: :author,
          target_profile: lambda {|article| article.profile },
          value: lambda { |article, author| author.present? ? TextArticle.where(author_id: author.id).count : 0 }
        },
      ],
      positive_votes_received: [
          {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voteable.author},
          target_profile: lambda {|vote| vote.voteable.profile },
          value: lambda { |vote, author| vote.voteable ? Vote.for_voteable(vote.voteable).where('vote > 0').count : 0}
        }
      ],
      negative_votes_received: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voteable.author},
          target_profile: lambda {|vote| vote.voteable.profile },
          value: lambda { |vote, author| Vote.for_voteable(vote.voteable).where('vote < 0').count }
        }
      ],
      votes_performed: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voter},
          target_profile: lambda {|vote| vote.voteable.profile },
          value: lambda { |vote, voter| voter ? Vote.for_voter(voter).count : 0 }
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
      manual: [],

#FIXME review the name of the badges and see a way to make it generic
      creative: [
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          target_profile: lambda {|comment| comment.profile },
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        },
        {
          action: 'article#create',
          default_threshold: 5,
          to: :author,
          target_profile: lambda {|article| article.profile },
          value: lambda { |article, author| author.present? ? author.articles.count : 0 }
        },
      ],
      observer: [
        {
          action: 'articlefollower#create',
          default_threshold: 5,
          to: lambda {|article| article.person },
          target_profile: lambda {|article_follower| article_follower.article.profile },
          model: 'ArticleFollower',
          value: lambda { |article, person| person.present? ? person.article_followers.count : 0 }
        }
      ],
      mobilizer: [
        {
          action: 'Vote#create',
          default_threshold: 5,
          to: lambda { |vote| vote.voter },
          target_profile: lambda {|vote| vote.voteable.profile },
          value: lambda { |vote, voter| Vote.for_voter(voter).count }
        },
        {
          action: 'Event#create',
          default_threshold: 5,
          to: lambda { |article| article.author },
          target_profile: lambda {|article| article.profile },
          value: lambda { |event, author| author.events.count }
        },
      ],
      generous: [
        {
          action: 'vote#create',
          default_threshold: 5,
          to: lambda {|vote| vote.voter},
          target_profile: lambda {|vote| vote.voteable.profile },
          value: lambda { |vote, voter| voter ? voter.votes.where('vote > 0').count : 0 }
        },
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          target_profile: lambda {|comment| comment.profile },
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        }
      ],
      articulator: [
        {
          action: 'articlefollower#create',
          default_threshold: 5,
          to: :person,
          target_profile: lambda {|article_follower| article_follower.article.profile },
          model: 'ArticleFollower',
          value: lambda { |article_follower, person| person.present? ? person.article_followers.count : 0 }
        },
        {
          action: 'comment#create',
          default_threshold: 5,
          to: :author,
          target_profile: lambda {|comment| comment.profile },
          value: lambda { |comment, author| author.present? ? author.comments.count : 0 }
        },
      ]
    }

    def target_author(source, setting)
      if setting[:to].is_a? Symbol
        source.send(setting[:to])
      else
        setting[:to].call(source) rescue nil
      end
    end

    def target_profile(source, setting)
      setting[:target_profile].present? ? setting[:target_profile].call(source) : nil
    end

    def check_organization_badge(badge, source, setting)
      !badge.owner.kind_of?(Organization) || badge.owner == target_profile(source, setting)
    end

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      rules = AVAILABLE_RULES
      rules.merge! CONFERENCE_RULES if defined? CONFERENCE_RULES

      environment.gamification_plugin_badges.each do |badge|
        next if rules[badge.name.to_sym].nil?
        rules[badge.name.to_sym].each do |setting|
          options = {badge: badge.name, level: badge.level, to: setting[:to]}
          options[:model_name] = setting[:model] unless setting[:model].nil?
          grant_on setting[:action], options do |source|
            can_be_granted = true
            rules[badge.name.to_sym].each do |s|
              to = target_author(source, setting)
              # pass source and to for different situations
              action = (badge.custom_fields || {}).fetch(s[:action], {})
              can_be_granted &= s[:value].call(source, to) >= action.fetch(:threshold, s[:default_threshold]).to_i
              can_be_granted &= check_organization_badge(badge, source, setting)
            end
            can_be_granted
          end
        end
      end
    end

  end
end
