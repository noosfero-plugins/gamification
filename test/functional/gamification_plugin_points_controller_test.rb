require 'test_helper'

class GamificationPluginPointsControllerTest < ActionController::TestCase

  setup do
    @environment = Environment.default
    login_as(create_admin_user(@environment))
  end

  should "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  should "should create gamification_plugin_point_categorizations for existing community" do
    community = fast_create(Community)
    create_all_point_rules
    count = GamificationPlugin::PointsType.count
    assert_difference('GamificationPlugin::PointsCategorization.for_profile(community.identifier).count', count) do
      post :create, identifier: community.identifier
    end
  end

  should "should create gamification_plugin_point_categorizations for general rules" do
    create_all_point_rules
    count = GamificationPlugin::PointsType.count
    assert_difference('GamificationPlugin::PointsCategorization.count', count) do
      post :create, identifier: ''
    end
  end

  should "should not create gamification_plugin_point_categorizations for not existing community" do
    create_all_point_rules
    assert_no_difference('GamificationPlugin::PointsCategorization.count') do
      post :create, identifier: 'any_not_existent_community_name'
    end
  end

  should "should get edit" do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    get :edit, id: community.id
    assert_not_nil assigns(:profile)
    assert_not_nil assigns(:categories)
  end

  should "should update gamification_plugin_points" do
    community = fast_create(Community)
    create_point_rule_definition('article_author', community)
    weights = {}
    GamificationPlugin::PointsCategorization.for_profile(community.identifier).each do |c|
      weights[c.id] = {weight: c.weight+10}
    end
    put :edit, id: community.id, gamification_plugin_points_categorizations: weights
    weights.each do |id, w|
      c = GamificationPlugin::PointsCategorization.find id
      assert_equal c.weight, w[:weight]
    end
  end

  should "should destroy gamification_plugin_point" do
    community = fast_create(Community)
    create_point_rule_definition('article_author',  community)
    count = GamificationPlugin::PointsCategorization.for_profile(community.identifier).count
    assert_difference('GamificationPlugin::PointsCategorization.count',-count) do
      delete :destroy, id: community.id
    end
  end
end
