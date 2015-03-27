require_relative '../test_helper'

class GamificationPluginAdminControllerTest < ActionController::TestCase

  def setup
    @environment = Environment.default
    @person = create_user_with_permission('profile', 'edit_environment_features', Environment.default)
    login_as(@person.identifier)
  end

  attr_accessor :person, :environment

  should 'save point rules' do
    post :index, :settings => {:point_rules => {'comment_author' => {'weight' => '10'}}}
    @settings = Noosfero::Plugin::Settings.new(environment.reload, GamificationPlugin)
    assert_equal({:point_rules => {'comment_author' => {'weight' => '10'}}}, @settings.settings)
  end

  should 'load default weights for point rules' do
    get :index
    Merit::PointRules::AVAILABLE_RULES.each do |category, setting|
      assert_select 'input[name=?][value=?]', "settings[point_rules][#{category}[weight]]", setting[:default_weight]
    end
  end

  should 'load saved weights for point rules' do
    settings = Noosfero::Plugin::Settings.new(environment, GamificationPlugin, {})
    settings.set_setting(:point_rules, {'comment_author' => {'weight' => '500'}})
    settings.save!
    get :index
    assert_select 'input[name=?][value=?]', "settings[point_rules][comment_author[weight]]", 500
  end

end

