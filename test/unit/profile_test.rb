require_relative "../test_helper"

class ProfileTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    @profile = fast_create(Profile)
    @settings = GamificationPlugin.settings(environment)
    @settings.set_setting(:rank_rules, [
      {:level => 1, :points => 10},
      {:level => 2, :points => 20},
      {:level => 3, :points => 30}
    ])
    @settings.save!
  end

  attr_accessor :profile, :environment

  should 'calculate profile level' do
    profile.stubs(:points).returns(25)
    assert_equal 2, profile.gamification_plugin_calculate_level
  end

  should 'calculate profile last level' do
    profile.stubs(:points).returns(35)
    assert_equal 3, profile.gamification_plugin_calculate_level
  end

  should 'calculate profile first level' do
    profile.stubs(:points).returns(10)
    assert_equal 1, profile.gamification_plugin_calculate_level
  end

  should 'update profile level when the score changes' do
    GamificationPlugin.gamification_set_rules(environment)
    person = create_user('testuser').person
    assert_equal 0, person.level
    create(Article, :profile_id => profile.id, :author => person)
    assert_equal 3, person.reload.level
  end

  should 'return percentage of points earned in current level with no points' do
    profile.stubs(:points).returns(0)
    assert_equal 0, profile.gamification_plugin_level_percent
  end

  should 'return percentage of points earned in current level with full points' do
    profile.stubs(:points).returns(10)
    assert_equal 100, profile.gamification_plugin_level_percent
  end

  should 'return percentage of points earned in current level' do
    profile.stubs(:points).returns(4)
    assert_equal 40, profile.gamification_plugin_level_percent
  end

  should 'return percentage of points earned in last level' do
    profile.stubs(:level).returns(3)
    profile.stubs(:points).returns(35)
    assert_equal 100, profile.gamification_plugin_level_percent
  end

  should 'return percentage of points earned in an intermediate level' do
    profile.stubs(:level).returns(2)
    profile.stubs(:points).returns(25)
    assert_equal 50, profile.gamification_plugin_level_percent
  end

end
