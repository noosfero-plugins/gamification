require_relative "../test_helper"

class ArticleTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @environment = Environment.default
  end

  attr_accessor :person, :environment

  should 'add merit points to author when create a new article' do
    create_point_rule_definition('article_author')
    create(TextArticle, :profile_id => person.id, :author => person)
    assert_equal 1, person.score_points.count
    assert person.score_points.first.action.present?
  end

  should 'subtract merit points to author when destroy an article' do
    create_point_rule_definition('article_author')
    article = create(TextArticle, :profile_id => person.id, :author => person)
    assert_equal 1, person.score_points.count
    article.destroy
    assert_equal 2, person.score_points.count
    assert_equal 0, person.points
  end

  should 'add merit badge to author when create 5 new articles' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(TextArticle, :profile_id => person.id, :author => person) }
    assert_equal 'article_author', person.badges.first.name
    assert_equal 1, person.badges.first.level
  end

  should 'add merit badge level 2 to author when create 10 new articles' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 2, :custom_fields => {:threshold => 10})
    GamificationPlugin.gamification_set_rules(environment)

    10.times { create(TextArticle, :profile_id => person.id, :author => person) }
    assert_equal ['article_author'], person.badges.map(&:name).uniq
    assert_equal [1, 2], person.badges.map(&:level)
  end

  should 'add merit points to community article owner when an user like it' do
    create_point_rule_definition('vote_voteable_author')
    community = fast_create(Community)
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to article when an user like it' do
    create_point_rule_definition('vote_voteable')
    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)
    article = article.reload

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable).first
    assert_difference 'article.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to community when create a new article' do
    create_point_rule_definition('article_community')
    community = fast_create(Community)
    assert_difference 'community.score_points.count' do
      create(TextArticle, :profile_id => community.id, :author => person)
    end
  end

  should 'add merit points to voter when he likes an article' do
    create_point_rule_definition('vote_voter')
    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to voter when he dislikes an article' do
    create_point_rule_definition('vote_voter')
    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => -1)
    end
  end

  should 'add badge to author when users like his article' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'positive_votes_received')
    GamificationPlugin.gamification_set_rules(environment)

    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)
    4.times { Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1) }
    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1)
    assert_equal [], person.badges
    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1)
    assert_equal 'positive_votes_received', person.reload.badges.first.name
  end

  should 'add badge to author when users dislike his article' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'negative_votes_received')
    GamificationPlugin.gamification_set_rules(environment)

    article = create(TextArticle, :name => 'Test', :profile => person, :author => person)
    4.times { Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1) }
    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => 1)
    assert_equal [], person.badges
    Vote.create!(:voter => fast_create(Person), :voteable => article, :vote => -1)
    assert_equal 'negative_votes_received', person.reload.badges.first.name
  end

  # community related tests
  should 'add merit community points to author when create a new article on community' do
    community = fast_create(Community)
    rule = create_point_rule_definition('article_author', community)
    create(TextArticle, profile_id: community.id, author_id: person.id)
    assert_equal rule.weight, person.points_by_profile(community.identifier)
    assert person.score_points.first.action.present?
  end

  should 'subtract merit points to author when destroy an article on community' do
    community = fast_create(Community)
    rule = create_point_rule_definition('article_author', community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    assert_equal rule.weight, person.points_by_profile(community.identifier)
    article.destroy
    assert_equal 0, person.points
  end

  should 'add merit points to community article owner when an user like it on community' do
    community = fast_create(Community)
    create_point_rule_definition('vote_voteable_author', community)
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to article when an user like it on community' do
    community = fast_create(Community)
    create_point_rule_definition('vote_voteable', community)
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)
    article = article.reload

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable).first
    assert_difference 'article.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to community when create a new article on community' do
    community = fast_create(Community)
    create_point_rule_definition('article_community')
    assert_difference 'community.score_points.count' do
      create(TextArticle, :profile_id => community.id, :author => person)
    end
  end

  should 'add merit points to voter when he likes an article on community' do
    community = fast_create(Community)
    create_point_rule_definition('vote_voter', community)
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => 1)
    end
  end

  should 'add merit points to voter when he dislikes an article on community' do
    community = fast_create(Community)
    create_point_rule_definition('vote_voter', community)
    article = create(TextArticle, :name => 'Test', :profile => community, :author => person)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'article.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => article, :vote => -1)
    end
  end

  should "add organization's merit badge to author when create 5 new articles" do
    organization = fast_create(Organization)
    GamificationPlugin::Badge.create!(:owner => organization, :name => 'article_author', :level => 1)
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(TextArticle, :profile_id => organization.id, :author => person) }
    assert_equal 'article_author', person.badges.first.name
    assert_equal 1, person.badges.first.level
  end

  should "do not earn organization's badge when the article is not posted in the organization itself" do
    organization = fast_create(Organization)
    other_organization = fast_create(Organization)
    GamificationPlugin::Badge.create!(:owner => organization, :name => 'article_author', :level => 1)
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(TextArticle, :profile_id => other_organization.id, :author => person) }
    assert_equal [], person.badges
  end

  should 'restore article object from action' do
    create_point_rule_definition('article_author')
    article = create(TextArticle, :profile_id => person.id, :author => person)
    assert_equal 1, person.score_points.count
    assert_equal article, person.score_points.first.action.target_obj
  end

end
