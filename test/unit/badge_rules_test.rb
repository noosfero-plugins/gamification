require_relative "../test_helper"

class BadgeRulesTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
  end

  attr_accessor :environment

  should "define badge rules for environment's badges" do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => :comment_author)
    badge_rules = Merit::BadgeRules.new(environment)
    assert_equal [Merit::BadgeRules::AVAILABLE_RULES[badge.name].first[:action]], badge_rules.defined_rules.keys
  end

  should "define badge rules for organization's badges" do
    organization = fast_create(Organization)
    badge = GamificationPlugin::Badge.create!(:owner => organization, :name => :comment_author)
    badge_rules = Merit::BadgeRules.new(environment)
    assert_equal [Merit::BadgeRules::AVAILABLE_RULES[badge.name].first[:action]], badge_rules.defined_rules.keys
  end

  should 'check organization returns true when badge belongs to the environment' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => :comment_author)
    badge_rules = Merit::BadgeRules.new(environment)
    comment = fast_create(Comment)
    assert badge_rules.check_organization_badge(badge, comment, Merit::BadgeRules::AVAILABLE_RULES[badge.name].first)
  end

  should 'check organization returns true when the comment belongs to the organization' do
    organization = fast_create(Organization)
    badge = GamificationPlugin::Badge.create!(:owner => organization, :name => :comment_author)
    badge_rules = Merit::BadgeRules.new(environment)
    article = fast_create(Article,:profile_id => organization.id)
    comment = fast_create(Comment, :source_id => article.id)
    assert badge_rules.check_organization_badge(badge, comment, Merit::BadgeRules::AVAILABLE_RULES[badge.name].first)
  end

  should 'check organization returns false when the comment does not belongs to the organization' do
    organization = fast_create(Organization)
    badge = GamificationPlugin::Badge.create!(:owner => organization, :name => :comment_author)
    badge_rules = Merit::BadgeRules.new(environment)
    comment = fast_create(Comment)
    assert !badge_rules.check_organization_badge(badge, comment, Merit::BadgeRules::AVAILABLE_RULES[badge.name].first)
  end

end
