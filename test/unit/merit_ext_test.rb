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

  should 'return target object associated to the merit action' do
    article = fast_create(Article)
    action = Merit::Action.new
    action.target_model = article.class.base_class.name
    action.target_id = article.id
    assert_equal article, action.target_obj
  end

end
