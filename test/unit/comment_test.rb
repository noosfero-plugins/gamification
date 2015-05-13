require_relative "../test_helper"

class CommentTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @article = create(TextileArticle, :profile_id => person.id)
    @environment = Environment.default
    GamificationPlugin.gamification_set_rules(@environment)
  end
  attr_accessor :person, :article, :environment

  should 'add merit points to author when create a new comment' do
    create(Comment, :source => article, :author_id => person.id)
    assert_equal 1, person.score_points.count
  end

  should 'subtract merit points from author when destroy a comment' do
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

  should 'add badge to author when users vote in his comment' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'relevant_commenter')
    GamificationPlugin.gamification_set_rules(environment)

    comment = create(Comment, :source => article, :author_id => person.id)
    4.times { Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => 1) }
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => -1)
    assert_equal [], person.badges
    Vote.create!(:voter => fast_create(Person), :voteable => comment, :vote => 1)
    assert_equal 'relevant_commenter', person.reload.badges.first.name
  end

  should 'add merit points to comment owner when an user like his comment' do
    comment = create(Comment, :source => article, :author_id => person.id)

    assert_difference 'comment.author.points(:category => :vote_voteable_author)', 50 do
      Vote.create!(:voter => person, :voteable => comment, :vote => 1)
    end
  end

  should 'subtract merit points to comment owner when an user unlike his comment' do
    comment = create(Comment, :source => article, :author_id => person.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => 1)

    assert_difference 'comment.author.points', -50 do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

  should 'subtract merit points from comment owner when an user dislike his comment' do
    comment = create(Comment, :source => article, :author_id => person.id)

    assert_difference 'comment.author.points(:category => :vote_voteable_author)', -50 do
      Vote.create!(:voter => person, :voteable => comment, :vote => -1)
    end
  end

  should 'add merit points from comment owner when an user remove a dislike in his comment' do
    comment = create(Comment, :source => article, :author_id => person.id)
    Vote.create!(:voter => person, :voteable => comment, :vote => -1)

    assert_difference 'comment.author.points', 50 do
      Vote.where(:voteable_id => comment.id).destroy_all
    end
  end

end
