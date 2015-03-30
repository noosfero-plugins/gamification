require_relative "../test_helper"

class ArticleTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @environment = Environment.default
    GamificationPlugin.gamification_set_rules(@environment)
  end

  attr_accessor :person, :environment

  should 'add merit points to author when create a new article' do
    create(Article, :profile_id => person.id, :author => person)
    assert_equal 1, person.score_points.count
  end

  should 'subtract merit points to author when destroy an article' do
    article = create(Article, :profile_id => person.id, :author => person)
    assert_equal 1, person.score_points.count
    article.destroy
    assert_equal 2, person.score_points.count
    assert_equal 0, person.points
  end

  should 'add merit badge to author when create 5 new articles' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(Article, :profile_id => person.id, :author => person) }
    assert_equal 'article_author', person.badges.first.name
    assert_equal 1, person.badges.first.level
  end

  should 'add merit badge level 2 to author when create 10 new articles' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 2, :custom_fields => {:threshold => 10})
    GamificationPlugin.gamification_set_rules(environment)

    10.times { create(Article, :profile_id => person.id, :author => person) }
    assert_equal ['article_author'], person.badges.map(&:name).uniq
    assert_equal [1, 2], person.badges.map(&:level)
  end

  should 'add merit points to article owner when an user like it' do
    article = create(Article, :name => 'Test', :profile => person, :author => person)

    assert_difference 'article.author.points(:category => :vote_voteable_author)', 5 do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to article when an user like it' do
    article = create(Article, :name => 'Test', :profile => person, :author => person)
    article = article.reload

    assert_difference 'article.points(:category => :vote_voteable)', 5 do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

end
