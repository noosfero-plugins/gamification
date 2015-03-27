require_relative '../test_helper'

class GamificationPluginProfileControllerTest < ActionController::TestCase

  def setup
    @profile = fast_create(Profile)
    @person = create_user('person').person
    login_as(@person.identifier)
  end

  attr_accessor :profile, :person

  should 'display points in gamification info page' do
    Profile.any_instance.expects(:points).returns(125)
    get :info, :profile => profile.identifier
    assert_tag :div, :attributes => {:class => 'score'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '125'}
  end

  should 'display level in gamification info page' do
    person.update_attribute(:level, 12)
    get :info, :profile => profile.identifier
    assert_tag :div, :attributes => {:class => 'level'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '12'}
  end

end
