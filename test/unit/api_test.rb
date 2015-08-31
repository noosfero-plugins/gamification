require_relative '../test_helper'
require_relative '../../../../test/unit/api/test_helper'

class APITest <  ActiveSupport::TestCase

  def setup
    login_api
    environment = Environment.default
    environment.enable_plugin(GamificationPlugin)
  end

  should 'get badges my own badges' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/my/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 'test_badge', json.first['name']
  end

  should 'get badges of the public person' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    another_person = create(User, :environment => environment).person
    another_person.visible=true
    another_person.save
    another_person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/people/#{another_person.id}/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 'test_badge', json.first['name']
  end

  should 'not get badges of the private person' do
    badge = GamificationPlugin::Badge.create!(:owner => environment, :name => 'test_badge')
    another_person = create(User, :environment_id => environment.id).person
    another_person.visible=false
    another_person.save
    another_person.add_badge(badge.id)
    get "/api/v1/gamification_plugin/people/#{another_person.id}/badges?#{params.to_query}"
    json = JSON.parse(last_response.body)
    assert_equal 404, last_response.status
  end

end
