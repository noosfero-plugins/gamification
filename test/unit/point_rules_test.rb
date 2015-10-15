require_relative "../test_helper"

class PointRulesTest < ActiveSupport::TestCase

  def setup
    @environment = Environment.default
    GamificationPlugin.gamification_set_rules(@environment)
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

end
