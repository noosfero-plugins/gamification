require_relative '../test_helper'

class GamificationPluginAdminControllerTest < ActionController::TestCase

  def setup
    @environment = Environment.default
    @person = create_user_with_permission('profile', 'edit_environment_features', Environment.default)
    login_as(@person.identifier)
  end

  attr_accessor :person, :environment

  should 'save rank rules' do
    post :levels, :settings => {:rank_rules => [{:level => 1, :points => 10}]}
    @settings = Noosfero::Plugin::Settings.new(environment.reload, GamificationPlugin)
    assert_equal({:rank_rules => [{'level' => '1', 'points' => '10'}]}, @settings.settings)
  end

  should 'load saved levels' do
    settings = Noosfero::Plugin::Settings.new(environment, GamificationPlugin, {})
    settings.set_setting(:rank_rules, [{'level' => '1', 'points' => '10'}, {'level' => '2', 'points' => '20'}])
    settings.save!
    get :levels
    assert_select 'input[name=?][value=?]', "settings[rank_rules][][points]", 10
    assert_select 'input[name=?][value=?]', "settings[rank_rules][][points]", 20
  end

end

