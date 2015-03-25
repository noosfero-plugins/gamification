# Be sure to restart your server when you modify this file.
#
# Points are a simple integer value which are given to "meritable" resources
# according to rules in +app/models/merit/point_rules.rb+. They are given on
# actions-triggered, either to the action user or to the method (or array of
# methods) defined in the +:to+ option.
#
# 'score' method may accept a block which evaluates to boolean
# (recieves the object as parameter)

module Merit
  class PointRules
    include Merit::PointRulesMethods

    AVAILABLE_RULES = {
      :comment_author => {
        :action => 'comment#create',
        :undo_action => 'comment#destroy',
        :to => :author,
        :value => 1
      },
      :article_author => {
        :action => 'article#create',
        :undo_action => 'article#destroy',
        :to => :author,
        :value => 1
      },
      :vote_voteable_author => {
        :action => 'vote#create',
        :undo_action => 'vote#destroy',
        :to => lambda {|vote| vote.voteable.author},
        :profile => lambda {|vote| vote.voteable.profile},
        :value => lambda {|vote| vote.vote}
      },
      :vote_voteable => {
        :action => 'vote#create',
        :undo_action => 'vote#destroy',
        :to => lambda {|vote| vote.voteable},
        :profile => lambda {|vote| vote.voteable.profile},
        :value => lambda {|vote| vote.vote}
      },
    }

    # FIXME get value from environment
    def weight(action)
      case action
      when :comment_author
        10
      when :article_author
        50
      when :vote_voteable
        5
      when :vote_voteable_author
        5
      end
    end

    def calculate_score(target, action, value)
      value = value.call(target) if value.respond_to?(:call)
      weight(action) * value
    end

    def initialize
      AVAILABLE_RULES.each do |key, setting|
        score lambda {|target| calculate_score(target, key, setting[:value])}, :on => setting[:action], :to => setting[:to]
        if setting[:undo_action].present?
          score lambda {|target| -calculate_score(target, key, setting[:value])}, :on => setting[:undo_action], :to => setting[:to]
        end
      end

      #score lambda {|target| calculate_score(target, :comment_create, 1)},  :on => 'comment#create'
      #score lambda {|target| calculate_score(target, :comment_create, -1)}, :on => 'comment#destroy'

      #score lambda {|target| calculate_score(target, :article_create, 1)},  :on => 'article#create'
      #score lambda {|target| calculate_score(target, :article_create, -1)}, :on => 'article#destroy'

      #score lambda {|target| calculate_score(target, :vote_create, target.vote)}, :on => 'vote#create', :to => lambda {|vote| vote.voteable.author}
      #score lambda {|target| calculate_score(target, :vote_create, target.vote)}, :on => 'vote#create', :to => lambda {|vote| vote.voteable}
      #score lambda {|target| calculate_score(target, :vote_create, -target.vote)}, :on => 'vote#destroy', :to => lambda {|vote| vote.voteable.author}
    end
  end
end
