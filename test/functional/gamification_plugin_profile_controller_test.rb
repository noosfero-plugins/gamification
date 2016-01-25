require_relative '../test_helper'

class GamificationPluginProfileControllerTest < ActionController::TestCase

  def setup
    @person = create_user('person').person
    @environment = Environment.default
    login_as(@person.identifier)
  end

  attr_accessor :person, :environment

  should 'display points in gamification dashboard' do
    create_all_point_rules
    article = create(TextArticle, :profile_id => fast_create(Community).id, :author => person)
    create(Comment, :source => article, :author_id => create_user.person.id)
    get :dashboard, :profile => person.identifier
    assert_tag :div, :attributes => {:class => 'score article_author positive do_action'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => default_point_weight(:article_author).to_s}
    assert_tag :div, :attributes => {:class => 'score comment_article_author positive do_action'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => default_point_weight(:comment_article_author).to_s}
    assert_tag :div, :attributes => {:class => 'score total'}, :child => {:tag => 'span', :attributes => {:class => 'value'}, :content => (default_point_weight(:comment_article_author) + default_point_weight(:article_author)).to_s}
  end

  should 'display level in gamification dashboard' do
    person.update_attribute(:level, 12)
    get :dashboard, :profile => person.identifier
    assert_tag :div, :attributes => {:class => 'level pie-chart', 'data-percent' => '100'}, :child => {:tag => 'span', :content => '12'}
  end

  should 'display person badges' do
    badge1 = GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 1)
    badge2 = GamificationPlugin::Badge.create!(:owner => environment, :name => 'article_author', :level => 2, :custom_fields => {:threshold => 10})
    GamificationPlugin.gamification_set_rules(environment)

    person.add_badge(badge1.id)
    person.add_badge(badge2.id)
    get :dashboard, :profile => person.identifier
    assert_select '.badges .badge-list li.badge', 1
  end

end
