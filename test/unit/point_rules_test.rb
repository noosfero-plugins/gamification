require_relative "../test_helper"

class PointRulesTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    GamificationPlugin.gamification_set_rules(@environment)
    @point_rules = Merit::PointRules.new(@environment)
  end

  attr_accessor :environment, :point_rules

  should 'not define rules when environment is nil' do
    point_rules = Merit::PointRules.new
    assert point_rules.defined_rules.blank?
  end

  should 'define rules when environment is present' do
    assert point_rules.defined_rules.present?
  end

  should 'return target url for a point related to article creation' do
    person = create_user('testuser').person
    create_point_rule_definition('article_author')
    article = create(TextArticle, :profile_id => person.id, :author => person)
    url = Merit::PointRules.target_url(person.score_points.last)
    assert_equal article.url, url
  end

  should 'return target url for a point related to comment creation' do
    person = create_user('testuser').person
    create_point_rule_definition('comment_author')
    article = create(Article, :profile_id => person.id, :author => person)
    comment = create(Comment, :source_id => article.id, :author => person)
    url = Merit::PointRules.target_url(person.score_points.last)
    assert_equal comment.url, url
  end

end
