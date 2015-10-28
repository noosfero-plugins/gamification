module Merit
  class PointRules
    include Merit::PointRulesMethods

    AVAILABLE_RULES = {
      comment_author: {
        action: 'comment#create',
        undo_action: 'comment#destroy',
        to: :author,
        value: 1,
        description: _('Comment author'),
        default_weight: 40,
        target_profile: lambda {|comment| comment.source.profile },
      },
      comment_article_author: {
        action: 'comment#create',
        undo_action: 'comment#destroy',
        to: lambda {|comment| comment.source.author},
        value: 1,
        description: _('Article author of a comment'),
        default_weight: 50,
        target_profile: lambda {|comment| comment.source.profile },
      },
      comment_article: {
        action: 'comment#create',
        undo_action: 'comment#destroy',
        to: lambda {|comment| comment.source},
        value: 1,
        description: _('Source article of a comment'),
        default_weight: 50,
        target_profile: lambda {|comment| comment.source.profile },
      },
      comment_community: {
        action: 'comment#create',
        undo_action: 'comment#destroy',
        to: lambda {|comment| comment.profile},
        value: 1,
        description: _('Article community of a comment'),
        default_weight: 50,
        target_profile: lambda {|comment| comment.source.profile },
        condition: lambda {|comment, profile| comment.profile.community?}
      },
      article_author: {
        action: 'article#create',
        undo_action: 'article#destroy',
        to: :author,
        value: 1,
        description: _('Article author'),
        default_weight: 50,
        target_profile: lambda {|article| article.profile },
      },
      article_community: {
        action: 'article#create',
        undo_action: 'article#destroy',
        to: :profile,
        value: 1,
        description: _('Article community'),
        default_weight: 10,
        target_profile: lambda {|article| article.profile },
        condition: lambda {|article, profile| article.profile.present? and article.profile.community? }
      },
      vote_voteable_author: {
        action: 'vote#create',
        undo_action: 'vote#destroy',
        to: lambda {|vote| vote.voteable.author},
        value: lambda {|vote| vote.vote},
        description: _('Author of a voted content'),
        default_weight: 20,
        target_profile: lambda {|vote| vote.voteable.present? ? vote.voteable.profile : nil },
      },
      vote_voteable: {
        action: 'vote#create',
        undo_action: 'vote#destroy',
        to: lambda {|vote| vote.voteable},
        value: lambda {|vote| vote.vote},
        description: _('Voted content'),
        default_weight: 30,
        target_profile: lambda {|vote| vote.voteable.present? ? vote.voteable.profile : nil },
      },
      vote_voter: {
        action: 'vote#create',
        undo_action: 'vote#destroy',
        to: lambda {|vote| vote.voter},
        value: lambda {|vote| 1},
        description: _('Voter'),
        default_weight: 10,
        target_profile: lambda {|vote| vote.voteable.present? ? vote.voteable.profile : nil },
      },
      friends: {
        action: 'friendship#create',
        undo_action: 'friendship#destroy',
        to: lambda {|friendship| friendship.person},
        value: 1,
        description: _('Friends'),
        default_weight: 5,
      },
      profile_completion: {
        action: ['profile#create', 'profile#update'],
        undo_action: 'profile#destroy',
        to: :itself,
        value: 1,
        description: _('Profile Completion'),
        default_weight: 100,
        condition: lambda {|person, profile| person.person? and person.profile_completion_score_condition },
      },
      follower: {
        action: 'articlefollower#create',
        undo_action: 'articlefollower#destroy',
        to: :person,
        value: 1,
        description: _('Follower'),
        default_weight: 10,
        model: 'ArticleFollower',
        target_profile: lambda {|follow| follow.article.profile },
      },
      followed_article: {
        action: 'articlefollower#create',
        undo_action: 'articlefollower#destroy',
        to: lambda {|follow| follow.article },
        value: 1,
        description: _('Article followed'),
        default_weight: 30,
        model: 'ArticleFollower',
        target_profile: lambda {|follow| follow.article.profile },
      },
      followed_article_author: {
        action: 'articlefollower#create',
        undo_action: 'articlefollower#destroy',
        to: lambda {|follow| follow.article.author },
        value: 1,
        description: _('Author of a followed content'),
        default_weight: 20,
        model: 'ArticleFollower',
        target_profile: lambda {|follow| follow.article.profile },
      }
    }

    def calculate_score(target, weight, value)
      value = value.call(target) if value.respond_to?(:call)
      weight * value
    end

    def condition(setting, target, profile)
      condition = setting[:condition]
      if condition.present?
        condition.call(target, profile)
      else
        true
      end
    end

    def profile_condition(setting, target, profile)
      profile.nil? || setting[:target_profile].blank? || setting[:target_profile].call(target) == profile
    end

    def self.setup
      return unless GamificationPlugin::PointsType.table_exists? && GamificationPlugin::PointsCategorization.table_exists?

      AVAILABLE_RULES.map do |rule_name, rule|
        point_type = GamificationPlugin::PointsType.find_by_name rule_name
        point_type = GamificationPlugin::PointsType.create name: rule_name, description: rule['description'] if point_type.nil?
        GamificationPlugin::PointsCategorization.create point_type_id: point_type.id, weight: rule[:default_weight]
      end
    end

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      AVAILABLE_RULES.each do |point_type, setting|
        GamificationPlugin::PointsCategorization.for_type(point_type).includes(:profile).each do |categorization|
          [setting[:action], setting[:undo_action]].compact.zip([1, -1]).each do |action, signal|
            options = {on: action, to: setting[:to], category: categorization.id.to_s}
            options[:model_name] = setting[:model] unless setting[:model].nil?
            weight = categorization.weight
            profile = categorization.profile
            score lambda {|target| signal * calculate_score(target, weight, setting[:value])}, options do |target|
              profile_condition(setting, target, profile) && condition(setting, target, profile)
            end
          end
        end
      end
    end

  end
end
