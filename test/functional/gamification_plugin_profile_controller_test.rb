require_relative '../test_helper'

class GamificationPluginProfileControllerTest < ActionController::TestCase

  def setup
    @profile = fast_create(Profile)
    @person = create_user('person').person
    login_as(@person.identifier)
  end

  attr_accessor :profile, :person

  should 'display points in gamification info page' do
    person.add_points(20, :category => :comment_author)
    person.add_points(30, :category => :article_author)
    get :info, :profile => profile.identifier
    assert_tag :div, :attributes => {:class => 'score article_author'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '30'}
    assert_tag :div, :attributes => {:class => 'score comment_author'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '20'}
    assert_tag :div, :attributes => {:class => 'score total'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '50'}
  end

  should 'display level in gamification info page' do
    person.update_attribute(:level, 12)
    get :info, :profile => profile.identifier
    assert_tag :span, :attributes => {:class => 'level'}, :content => '12'
  end

  should 'display person badges' do
    person.add_badge(1)
    person.add_badge(2)
    get :info, :profile => profile.identifier
    assert_select '.badges .badge-list .badge', 2
  end

end
