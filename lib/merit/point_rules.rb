module Merit
  class PointRules
    include Merit::PointRulesMethods

    AVAILABLE_RULES = {
      :comment_author => {
        :action => 'comment#create',
        :undo_action => 'comment#destroy',
        :to => :author,
        :value => 1,
        :description => _('Point weight for comment author'),
        :default_weight => 150
      },
      :comment_article_author => {
        :action => 'comment#create',
        :undo_action => 'comment#destroy',
        :to => lambda {|comment| comment.source.author},
        :value => 1,
        :description => _('Point weight for article author of a comment'),
        :default_weight => 50
      },
      :comment_article => {
        :action => 'comment#create',
        :undo_action => 'comment#destroy',
        :to => lambda {|comment| comment.source},
        :value => 1,
        :description => _('Point weight for source article of a comment'),
        :default_weight => 50
      },
      :comment_community => {
        :action => 'comment#create',
        :undo_action => 'comment#destroy',
        :to => lambda {|comment| comment.profile},
        :value => 1,
        :description => _('Point weight for article community of a comment'),
        :default_weight => 50,
        :condition => lambda {|target| target.profile.community? }
      },
      :article_author => {
        :action => 'article#create',
        :undo_action => 'article#destroy',
        :to => :author,
        :value => 1,
        :description => _('Point weight for article author'),
        :default_weight => 500
      },
      :article_community => {
        :action => 'article#create',
        :undo_action => 'article#destroy',
        :to => :profile,
        :value => 1,
        :description => _('Point weight for article community'),
        :default_weight => 600,
        :condition => lambda {|target| target.profile.community? }
      },
      :vote_voteable_author => {
        :action => 'vote#create',
        :undo_action => 'vote#destroy',
        :to => lambda {|vote| vote.voteable.author},
        :profile => lambda {|vote| vote.voteable.profile},
        :value => lambda {|vote| vote.vote},
        :description => _('Point weight for the author of a voted content'),
        :default_weight => 50,
        :condition => lambda {|vote| vote.voteable.profile.community? }
      },
      :vote_voteable => {
        :action => 'vote#create',
        :undo_action => 'vote#destroy',
        :to => lambda {|vote| vote.voteable},
        :profile => lambda {|vote| vote.voteable.profile},
        :value => lambda {|vote| vote.vote},
        :description => _('Point weight for a voted content'),
        :default_weight => 50
      },
      :vote_voter => {
        :action => 'vote#create',
        :undo_action => 'vote#destroy',
        :to => lambda {|vote| vote.voter},
        :value => lambda {|vote| 1},
        :description => _('Point weight for a voter'),
        :default_weight => 10
      },
    }

    def weight(category)
      settings = Noosfero::Plugin::Settings.new(@environment, GamificationPlugin)
      settings.settings.fetch(:point_rules, {}).fetch(category.to_s, {}).fetch('weight', AVAILABLE_RULES[category][:default_weight]).to_i
    end

    def calculate_score(target, category, value)
      value = value.call(target) if value.respond_to?(:call)
      weight(category) * value
    end

    def condition(setting, target)
      condition = setting[:condition]
      condition.present? ? condition.call(target) : true
    end

    def initialize(environment=nil)
      return if environment.nil?
      @environment = environment

      AVAILABLE_RULES.each do |category, setting|
        [setting[:action], setting[:undo_action]].compact.zip([1, -1]).each do |action, signal|
          score lambda {|target| signal * calculate_score(target, category, setting[:value])}, :on => action, :to => setting[:to], :category => category do |target|
            condition(setting, target)
          end
        end
      end
    end

  end
end
