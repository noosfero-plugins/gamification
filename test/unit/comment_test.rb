require_relative "../test_helper"

class CommentTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @author = create_user('testauthoruser').person
    @article = create(TextileArticle, :profile_id => @person.id, :author_id => @author.id)
    @environment = Environment.default
  end
  attr_accessor :person, :article, :environment, :author

  should 'add merit points to author when create a new comment' do
    create_point_rule_definition('comment_author')
    create(Comment, :source => article, :author_id => person.id)
    assert_equal 1, person.score_points.count
  end

  should 'subtract merit points from author when destroy a comment' do
    create_point_rule_definition('comment_author')
    comment = create(Comment, :source => article, :author_id => person.id)
    assert_equal 1, person.score_points.count
    comment.destroy
    assert_equal 2, person.score_points.count
    assert_equal 0, person.points
  end

  should 'add merit badge to author when create 5 new comments' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'comment_author')
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(Comment, :source => article, :author_id => person.id) }
    assert_equal 'comment_author', person.badges.first.name
  end

  should 'add merit badge to source author when create 5 new comments' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'comment_received')
    GamificationPlugin.gamification_set_rules(environment)

    5.times { create(Comment, :source => article, :author_id => person.id) }
    assert_equal 'comment_received', author.badges.first.name
  end

  should 'add badge to author when users like his comment' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'positive_votes_received')
    GamificationPlugin.gamification_set_rules(environment)

    comment = create(Comment, :source => article, :author_id => person.id)
    4.times { Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => 1) }
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => -1)
    assert_equal [], person.badges
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => 1)
    assert_equal 'positive_votes_received', person.reload.badges.first.name
  end

  should 'add badge to author when users dislike his comment' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'negative_votes_received')
    GamificationPlugin.gamification_set_rules(environment)

    comment = create(Comment, :source => article, :author_id => person.id)
    4.times { Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => -1) }
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => 1)
    assert_equal [], person.badges
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => -1)
    assert_equal 'negative_votes_received', person.reload.badges.first.name
  end

  should 'add merit points to comment owner when an user like his comment' do
    create_point_rule_definition('vote_voteable_author')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => 1)
    end
  end

  should 'subtract merit points to comment owner when an user unlike his comment' do
    create_point_rule_definition('vote_voteable_author')
    comment = create(Comment, :source => article, :author_id => author.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => 1)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points', -1*c.weight do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

  should 'subtract merit points from comment owner when an user dislike his comment' do
    create_point_rule_definition('vote_voteable_author')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', -1*c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => -1)
    end
  end

  should 'add merit points from comment owner when an user remove a dislike in his comment' do
    create_point_rule_definition('vote_voteable_author')
    comment = create(Comment, :source => article, :author_id => author.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => -1)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points', c.weight do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

  should 'add merit points to article author when create a new comment' do
    create_point_rule_definition('comment_article_author')
    assert_difference 'author.score_points.count' do
      create(Comment, :source => article, :author_id => person.id)
    end
  end

  should 'add merit points to voter when he likes a comment' do
    create_point_rule_definition('vote_voter')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => 1)
    end
  end

  should 'add merit points to voter when he dislikes a comment' do
    create_point_rule_definition('vote_voter')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => -1)
    end
  end

  should 'add merit points to source article when create a comment' do
    create_point_rule_definition('comment_article')
    c = GamificationPlugin::PointsCategorization.for_type(:comment_article).first
    assert_difference 'article.points(:category => c.id.to_s)', c.weight do
      create(Comment, :source => article, :author_id => person.id)
    end
  end

  should 'add merit points to source community when create a comment' do
    create_point_rule_definition('comment_community')
    community = fast_create(Community)
    article = create(TextileArticle, :profile_id => community.id, :author_id => author.id)

    c = GamificationPlugin::PointsCategorization.for_type(:comment_community).first
    assert_difference 'community.points(:category => c.id.to_s)', c.weight do
      create(Comment, :source => article, :author_id => person.id)
    end
  end

  ## Community related tests
  should 'add merit community points to author when create a new comment in a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    rule = create_point_rule_definition('comment_author', article.profile)
    create(Comment, :source => article, :author_id => person.id)
    assert_equal rule.weight, person.points_by_profile(article.profile.identifier)
  end

  should 'subtract merit community points from author when destroy a community comment' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: fast_create(Person).id)
    rule = create_point_rule_definition('comment_author', article.profile)
    comment = create(Comment, :source => article, :author_id => person.id)
    assert_equal rule.weight, person.points_by_profile(article.profile.identifier)
    comment.destroy
    assert_equal 0, person.points_by_profile(article.profile.identifier)
  end

  should 'add merit communty points to comment owner when an user like his comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voteable_author', community)
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).where(profile_id: article.profile.id).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => 1)
    end
  end

  should 'subtract merit community points to comment owner when an user unlike his comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voteable_author', community)
    comment = create(Comment, :source => article, :author_id => author.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => 1)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points_by_profile(community.identifier)', -1*c.weight do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

  should 'subtract merit community points from comment owner when an user dislike his comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voteable_author', community)
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).where(profile_id: article.profile.id).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', -1*c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => -1)
    end
  end

  should 'add merit community points from comment owner when an user remove a dislike in his comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voteable_author', community)
    comment = create(Comment, :source => article, :author_id => author.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => -1)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voteable_author).first
    assert_difference 'comment.author.points_by_profile(community.identifier)', c.weight do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

  should 'add merit community points to article author when create a new comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: author.id)
    rule = create_point_rule_definition('comment_article_author', community)
    assert_difference 'author.points_by_profile(community.identifier)', rule.weight do
      create(Comment, :source => article, :author_id => author.id)
    end
  end

  should 'add merit community points to voter when he likes a comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voter')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => 1)
    end
  end

  should 'add merit community points to voter when he dislikes a comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('vote_voter')
    comment = create(Comment, :source => article, :author_id => person.id)

    c = GamificationPlugin::PointsCategorization.for_type(:vote_voter).first
    assert_difference 'comment.author.points(:category => c.id.to_s)', c.weight do
      Vote.create!(:voter => person, :voteable => comment, :vote => -1)
    end
  end

  should 'add merit community points to source article when create a comment inside a community' do
    community = fast_create(Community)
    article = create(TextArticle, profile_id: community.id, author_id: person.id)
    create_point_rule_definition('comment_article')
    c = GamificationPlugin::PointsCategorization.for_type(:comment_article).first
    assert_difference 'article.points(:category => c.id.to_s)', c.weight do
      create(Comment, :source => article, :author_id => person.id)
    end
  end

  should 'add merit community points to source community when create a comment' do
    create_point_rule_definition('comment_community')
    community = fast_create(Community)
    article = create(TextileArticle, :profile_id => community.id, :author_id => author.id)

    c = GamificationPlugin::PointsCategorization.for_type(:comment_community).first
    assert_difference 'community.points(:category => c.id.to_s)', c.weight do
      create(Comment, :source => article, :author_id => person.id)
    end
  end


end
