require_relative "../test_helper"

class MeritExtTest < ActiveSupport::TestCase

  should 'check if the point was originated by an undo action' do
    point = Merit::Score::Point.new
    point_type = GamificationPlugin::PointsType.new(name: :comment_author)
    point.expects(:point_type).returns(point_type)
    action = mock
    action.expects(:target_model).returns('comment')
    action.expects(:action_method).returns('destroy')
    point.expects(:action).at_least_once.returns(action)
    assert point.undo_rule?
  end

  should 'check if the point was originated by a do action' do
    point = Merit::Score::Point.new
    point_type = GamificationPlugin::PointsType.new(name: :comment_author)
    point.expects(:point_type).returns(point_type)
    action = mock
    action.expects(:target_model).returns('comment')
    action.expects(:action_method).returns('create')
    point.expects(:action).at_least_once.returns(action)
    assert !point.undo_rule?
  end

end
