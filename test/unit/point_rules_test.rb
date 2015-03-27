require_relative "../test_helper"

class PointRulesTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    @point_rules = Merit::PointRules.new(@environment)
  end

  attr_accessor :environment, :point_rules

  should 'not define rules when environment is nil' do
    point_rules = Merit::PointRules.new
    assert point_rules.defined_rules.blank?
  end

  should 'define rules when environment is present' do
    assert point_rules.defined_rules.present?
  end

  should 'weight returns the default value when value is not setted in environment' do
    Merit::PointRules::AVAILABLE_RULES.each do |category, setting|
      assert_equal setting[:default_weight], point_rules.weight(category)
    end
  end

  should 'weight returns value from environment when it is setted' do
    settings = Noosfero::Plugin::Settings.new(environment, GamificationPlugin, {})
    settings.set_setting(:point_rules, {'comment_author' => {'weight' => '500'}})
    settings.save!
    assert_equal 500, point_rules.weight(:comment_author)
  end

end
