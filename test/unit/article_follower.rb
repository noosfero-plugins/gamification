require_relative "../test_helper"

class ArticleTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @environment = Environment.default
    @community = fast_create(Community)
  end

  attr_accessor :person, :environment, :community

  should 'add merit points to an article follower by user' do
    create_point_rule_definition('followed_article')
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:followed_article).first
    assert_difference 'article.points(:category => c.id.to_s)', c.weight do
      article.person_followers << person
    end
  end

  should 'add merit points to follower when it follows an article' do
    create_point_rule_definition('follower')

    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:follower).first
    assert_difference 'person.points(:category => c.id.to_s)', c.weight do
      article.person_followers << person
    end
  end

  should "add merit points for article's author followed by an user" do
    create_point_rule_definition('followed_article_author')

    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:followed_article_author).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      article.person_followers << person
    end
  end

  should 'subtract merit points to follower when it unfollow an article' do
    create_point_rule_definition('follower')
    follower = create_user('someuser').person
    article = create(TextArticle, :profile_id => community.id, :author => person)
    score_points = follower.score_points.count
    points = follower.points
    article.person_followers << follower
    assert_equal score_points + 1, follower.score_points.count
    ArticleFollower.last.destroy
    assert_equal score_points + 2, follower.score_points.count
    assert_equal points, follower.points
  end

  should 'subtract merit points to article author when a user unfollow an article' do
    create_point_rule_definition('follower')
    article = create(TextArticle, :profile_id => community.id, :author => person)
    score_points = person.score_points.count
    points = person.points
    article.person_followers << person
    assert_equal score_points + 1, person.score_points.count
    ArticleFollower.last.destroy
    assert_equal score_points + 2, person.score_points.count
    assert_equal points, person.points
  end

  should 'subtract merit points to article when a user unfollow an article' do
    create_point_rule_definition('followed_article')
    article = create(TextArticle, :profile_id => community.id, :author => person)
    score_points = article.score_points.count
    points = article.points
    article.person_followers << person
    assert_equal score_points + 1, article.score_points.count
    ArticleFollower.last.destroy
    assert_equal score_points + 2, article.score_points.count
    assert_equal points, article.points
  end

#FIXME make tests for badges generete with article follower actions
#
#  should 'add badge to author when users like his article' do
#    GamificationPlugin::Badge.create!(:owner => environment, :name => 'positive_votes_received')
#    GamificationPlugin.gamification_set_rules(environment)
#
#    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)
#    4.times { Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1) }
#    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1)
#    assert_equal [], person.badges
#    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1)
#    assert_equal 'positive_votes_received', person.reload.badges.first.name
#  end
#
#  should 'add badge to author when users dislike his article' do
#    GamificationPlugin::Badge.create!(:owner => environment, :name => 'negative_votes_received')
#    GamificationPlugin.gamification_set_rules(environment)
#
#    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)
#    4.times { Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1) }
#    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1)
#    assert_equal [], person.badges
#    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1)
#    assert_equal 'negative_votes_received', person.reload.badges.first.name
#  end
#
#  should 'add merit badge to author when create 5 new articles' do
#    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
#    GamificationPlugin.gamification_set_rules(environment)
#
#    5.times { create(TextArticle, :profile_id => person.id, :author => person) }
#    assert_equal 'article_author', person.badges.first.name
#    assert_equal 1, person.badges.first.level
#  end
#
#  should 'add merit badge level 2 to author when create 10 new articles' do
#    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
#    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 2, :custom_fields => {:threshold => 10})
#    GamificationPlugin.gamification_set_rules(environment)
#
#    10.times { create(TextArticle, :profile_id => person.id, :author => person) }
#    assert_equal ['article_author'], person.badges.map(&:name).uniq
#    assert_equal [1, 2], person.badges.map(&:level)
#  end
end
