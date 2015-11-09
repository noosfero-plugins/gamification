require_relative "../test_helper"

class DashboardHelperTest < ActiveSupport::TestCase

  include GamificationPlugin::DashboardHelper

  should 'return title for global badges' do
    owner = Environment.new
    assert_equal 'Badges', badges_title(owner)
  end

  should 'return title for organization badges' do
    owner = Organization.new(:name => 'organization')
    assert_equal 'Badges for organization', badges_title(owner)
  end

  should 'return badges grouped by owner' do
    environment = Environment.default
    expects(:environment).at_least_once.returns(environment)
    badge1 = GamificationPlugin::Badge.create!(:owner => fast_create(Organization))
    badge2 = GamificationPlugin::Badge.create!(:owner => environment)
    assert_equal [[badge2.owner, [badge2]], [badge1.owner, [badge1]]], grouped_badges
  end

  should 'return category of a score point' do
    point_type = GamificationPlugin::PointsType.create!(name: "point category", description: "point category")
    score = Merit::Score.new
    score.category = point_type.id.to_s
    score.save!
    point = score.score_points.create!
    assert_equal "point category", score_point_category(point)
  end

end
