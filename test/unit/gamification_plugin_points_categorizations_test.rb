require 'test_helper'

class GamificationPluginPointsCategorizationsTest < ActiveSupport::TestCase

  should 'require value for weight' do
    p = GamificationPlugin::PointsCategorization.new
    p.valid?
    assert p.errors[:weight].present?

    p.weight = 12
    p.valid?
    refute p.errors[:weight].present?
  end

  should 'require value for point type' do
    p = GamificationPlugin::PointsCategorization.new
    p.valid?
    assert p.errors[:point_type_id].present?

    p.point_type = GamificationPlugin::PointsType.create!(:name => 'some')
    p.valid?
    refute p.errors[:point_type_id].present?
  end

  should 'the point type be unique in profile scope' do
    point_type = GamificationPlugin::PointsType.create!(:name => 'some')
    profile = fast_create(Community)
    GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id, :profile_id => profile.id).save!

    p = GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id, :profile_id => profile.id)
    p.valid?
    assert p.errors[:point_type_id].present?
  end
  
  
  should 'the point type be unique in profile scope when profile is nil' do
    point_type = GamificationPlugin::PointsType.create!(:name => 'some')
    GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id).save!

    p = GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id)
    p.valid?
    assert p.errors[:point_type_id].present?
  end
  
  should 'the point type be used in differente profile scopes' do
    point_type = GamificationPlugin::PointsType.create!(:name => 'some')
    p1 = fast_create(Community)
    GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id, :profile_id => p1.id).save!

    p2 = fast_create(Community)
    p = GamificationPlugin::PointsCategorization.new(:weight => 10, :point_type_id => point_type.id, :profile_id => p2.id)
    p.valid?
    refute p.errors[:point_type_id].present?
  end
  
end
