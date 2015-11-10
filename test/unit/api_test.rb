require_relative '../test_helper'
require_relative '../../../../test/unit/api/test_helper'

class APITest <  ActiveSupport::TestCase

  def setup
    login_api
    environment = Environment.default
    environment.enable_plugin(GamificationPlugin)
    GamificationPlugin.gamification_set_rules(@environment)
    create_all_point_rules
  end

  should 'get my own badges' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/my/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 'test_badge', json['badges'].first['name']
  end

  should 'get my level' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/my/level?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_not_nil json['level']
    assert_not_nil json['percent']
  end

  should 'get badges of the public person' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    another_person = create(User, :environment => environment).person
    another_person.visible=true
    another_person.save
    another_person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/people/#{another_person.id}/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 'test_badge', json.first['name']
  end

  should 'get level of the public person' do
    another_person = create(User, :environment => environment).person
    another_person.visible=true
    another_person.save
    get "/api/v1/gamification_plugin/people/#{another_person.id}/level?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_not_nil json['level']
    assert_not_nil json['percent']
  end

  should 'not get badges of the private person' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    another_person = create(User, :environment_id => environment.id).person
    another_person.visible=false
    another_person.save
    another_person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/people/#{another_person.id}/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 404, last_response.status
  end

  should 'not get level of the private person' do
    another_person = create(User, :environment_id => environment.id).person
    another_person.visible=false
    another_person.save
    get "/api/v1/gamification_plugin/people/#{another_person.id}/level?#{params.to_query}"
    JSON.parse(last_response.body)
    assert_equal 404, last_response.status
  end

  should 'get amount of environment badges grouped by name' do
    3.times { GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge') }
    get "/api/v1/gamification_plugin/badges"
    json = JSON.parse(last_response.body)
    assert_equal 3, json['test_badge']
  end

  should 'get my points' do
    article = create(TextArticle, :profile_id => @person.id, :author => @person)
    create(Comment, :source_id => article.id, :author => fast_create(Person))

    get "/api/v1/gamification_plugin/my/points?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author) + default_point_weight(:comment_article_author), json['points']
  end

  should 'get my points filtered by type' do
    article = create(TextArticle, :profile_id => @person.id, :author => @person)
    create(Comment, :source_id => article.id, :author => fast_create(Person))
    params[:type] = 'article_author'

    get "/api/v1/gamification_plugin/my/points_by_type?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author), json['points']
  end

  should 'get my points filtered by profile' do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    create(TextArticle, :profile_id => @person.id, :author => @person)
    create(TextArticle, :profile_id => community.id, :author => @person)
    params[:profile] = community.identifier

    get "/api/v1/gamification_plugin/my/points_by_profile?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author), json['points']
  end

  should 'get my points excluding points earned in profiles' do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    create(TextArticle, :profile_id => @person.id, :author => @person)
    create(TextArticle, :profile_id => community.id, :author => @person)

    get "/api/v1/gamification_plugin/my/points_out_of_profiles?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 2*default_point_weight(:article_author), json['points']
  end

  should 'get points of a person' do
    article = create(TextArticle, :profile_id => @person.id, :author => @person)
    create(Comment, :source_id => article.id, :author => fast_create(Person))

    get "/api/v1/gamification_plugin/people/#{person.id}/points?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author) + default_point_weight(:comment_article_author), json['points']
  end

  should 'get points of a person filtered by type' do
    article = create(TextArticle, :profile_id => @person.id, :author => @person)
    create(Comment, :source_id => article.id, :author => fast_create(Person))
    params[:type] = 'article_author'

    get "/api/v1/gamification_plugin/people/#{@person.id}/points_by_type?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author), json['points']
  end

  should 'get points of a person filtered by profile' do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    create(TextArticle, :profile_id => @person.id, :author => @person)
    create(TextArticle, :profile_id => community.id, :author => @person)
    params[:profile] = community.identifier

    get "/api/v1/gamification_plugin/people/#{@person.id}/points_by_profile?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal default_point_weight(:article_author), json['points']
  end

  should 'get points of a person excluding points earned in profiles' do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    create(TextArticle, :profile_id => @person.id, :author => @person)
    create(TextArticle, :profile_id => community.id, :author => @person)

    get "/api/v1/gamification_plugin/people/#{@person.id}/points_out_of_profiles?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 2*default_point_weight(:article_author), json['points']
  end

end
