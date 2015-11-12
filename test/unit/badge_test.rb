require_relative "../test_helper"

class BadgeTest < ActiveSupport::TestCase

  def setup
    @person = create_user('testuser').person
    @environment = Environment.default
    @organization = fast_create(Organization)
  end

  attr_accessor :person, :environment, :organization

  should 'add badge to person' do
    badge = GamificationPlugin::Badge.create!(:owner => environment)
    person.add_badge(badge.id)
    assert_equal [badge], person.badges
  end

  should 'remove badge from person when destroy a badge' do
    badge = GamificationPlugin::Badge.create!(:owner => environment)
    person.add_badge(badge.id)
    assert_equal [badge], person.badges
    badge.destroy
    assert_equal [], person.reload.badges
  end

  should 'not fail when a person has an undefined badge' do
    person.add_badge(1235)
    assert_equal [], person.reload.badges.compact
  end

  should 'list pending badges from a person' do
    badge1 = GamificationPlugin::Badge.create!(:owner => environment)
    person.add_badge(badge1.id)
    person.sash.notify_all_badges_from_user
    badge2 = GamificationPlugin::Badge.create!(:owner => environment)
    person.add_badge(badge2.id)
    assert_equal [badge2], person.badges.notification_pending
  end

  should 'add badge to person with organization as the badge owner' do
    badge = GamificationPlugin::Badge.create(:owner => organization)
    person.add_badge(badge.id)
    assert_equal [badge], person.badges
  end

  should 'add a manual badge to person' do
    badge = GamificationPlugin::Badge.create!(:name => :manual, :owner => environment)
    person.add_badge(badge.id)
    assert_equal [badge], person.badges
  end

end
