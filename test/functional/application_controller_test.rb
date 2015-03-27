require_relative '../test_helper'
require 'test_controller'

class TestController; def rescue_action(e) raise e end; end

class ApplicationControllerTest < ActionController::TestCase

  def setup
    @environment = Environment.default
    @environment.enable_plugin(GamificationPlugin)
    @controller = TestController.new
    @controller.stubs(:environment).returns(@environment)
  end

  should 'redefine rules in before filter' do
    get :index
    assert Merit::AppPointRules.present?
  end

end
