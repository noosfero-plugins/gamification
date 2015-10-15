require_relative "../test_helper"

class GamificationPluginBadgesControllerTest < ActionController::TestCase

  setup do
    @environment = Environment.default
    @gamification_plugin_badge = GamificationPlugin::Badge.create!(:name => 'sample_badge', :owner => @environment)
    login_as(create_admin_user(@environment))
  end

  should "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gamification_plugin_badges)
  end

  should "should get new" do
    get :new
    assert_response :success
  end

  should "should create gamification_plugin_badge" do
    assert_difference('GamificationPlugin::Badge.count') do
      post :create, gamification_plugin_badge: { description: @gamification_plugin_badge.description, level: @gamification_plugin_badge.level, name: @gamification_plugin_badge.name, custom_fields: {threshold: @gamification_plugin_badge.threshold} }
    end
  end

  should "should show gamification_plugin_badge" do
    get :show, id: @gamification_plugin_badge
    assert_response :success
  end

  should "should get edit" do
    get :edit, id: @gamification_plugin_badge
    assert_response :success
  end

  should "should update gamification_plugin_badge" do
    put :update, id: @gamification_plugin_badge, gamification_plugin_badge: { description: @gamification_plugin_badge.description, level: @gamification_plugin_badge.level, name: @gamification_plugin_badge.name, custom_fields: {threshold: @gamification_plugin_badge.threshold} }
    assert assigns(:gamification_plugin_badge)
  end

  should "should destroy gamification_plugin_badge" do
    assert_difference('GamificationPlugin::Badge.count', -1) do
      delete :destroy, id: @gamification_plugin_badge
    end
  end
end
