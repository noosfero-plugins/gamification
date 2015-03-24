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

    def initialize
      score 10, :on => 'comment#create'
      score -10, :on => 'comment#destroy'

      score 50, :on => 'article#create'
      score -50, :on => 'article#destroy'

      score lambda {|vote| 5 * vote.vote}, :on => 'vote#create', :to => lambda {|vote| vote.voteable.author}
      score lambda {|vote| 5 * vote.vote}, :on => 'vote#create', :to => lambda {|vote| vote.voteable}
      score lambda {|vote| -5 * vote.vote}, :on => 'vote#destroy', :to => lambda {|vote| vote.voteable.author}
    end
  end
end
