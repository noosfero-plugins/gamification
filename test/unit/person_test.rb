require_relative "../test_helper"

class PersonTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    GamificationPlugin.gamification_set_rules(@environment)
    @person = create_user('testuser').person
  end
  attr_accessor :environment, :person

  should 'add badge to a voter' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'votes_performed')
    GamificationPlugin.gamification_set_rules(environment)

    4.times { Vote.create!(:voter => person, :voteable => fast_create(Comment), :vote => 1) }
    assert_equal [], person.badges
    Vote.create!(:voter => person, :voteable => fast_create(Comment), :vote => 1)
    assert_equal 'votes_performed', person.reload.badges.first.name
  end

  should 'add badge to a friendly person' do
    GamificationPlugin::Badge.create!(:owner => environment, :name => 'friendly')
    GamificationPlugin.gamification_set_rules(environment)

    5.times { |i| person.add_friend(create_user("testuser#{i}").person) }
    assert_equal 'friendly', person.reload.badges.first.name
  end

end
