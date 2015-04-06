require_relative '../../../../test/test_helper'

class GamificationPluginTest < ActiveSupport::TestCase

  def setup
    @plugin = GamificationPlugin.new
    @current_person = create_user('person').person
  end

  attr_accessor :plugin, :current_person

  should 'return user points and badges in user_data_extras' do
    assert_equal({:gamification_plugin => {:points => 0, :badges => [], :level => 0}}, instance_eval(&plugin.user_data_extras))
  end

end
