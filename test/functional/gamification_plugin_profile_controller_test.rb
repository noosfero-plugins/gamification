require_relative '../test_helper'

class GamificationPluginProfileControllerTest < ActionController::TestCase

  def setup
    @person = create_user('person').person
    @environment = Environment.default
    login_as(@person.identifier)
  end

  attr_accessor :person, :environment

  should 'display points in gamification info page' do
    person.add_points(20, :category => :comment_author)
    person.add_points(30, :category => :article_author)
    get :info, :profile => person.identifier
    assert_tag :div, :attributes => {:class => 'score article_author'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '30'}
    assert_tag :div, :attributes => {:class => 'score comment_author'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '20'}
    assert_tag :div, :attributes => {:class => 'score total'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => '50'}
  end

  should 'display level in gamification info page' do
    person.update_attribute(:level, 12)
    get :info, :profile => person.identifier
    assert_tag :span, :attributes => {:class => 'level'}, :content => '12'
  end

  should 'display person badges' do
    badge1 = GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    badge2 = GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 2, :custom_fields => {:threshold => 10})
    GamificationPlugin.gamification_set_rules(environment)

    person.add_badge(badge1.id)
    person.add_badge(badge2.id)
    get :info, :profile => person.identifier
    assert_select '.badges .badge-list .badge', 2
  end

end
