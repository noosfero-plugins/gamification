require 'test_helper'

class GamificationPluginPointsTypesTest < ActiveSupport::TestCase

  should 'require value for name' do
    p = GamificationPlugin::PointsType.new
    p.valid?
    assert p.errors[:name].present?

    p.name = 'some'
    p.valid?
    refute p.errors[:name].present?
  end

  should 'the name be unique' do
    GamificationPlugin::PointsType.new(:name => 'some').save!

    p = GamificationPlugin::PointsType.new(:name => 'some')
    p.valid?
    assert p.errors[:name].present?
  end


end
