#!/usr/bin/env ruby
# encoding: UTF-8

class ProcessObserver
  def update(changed_data)
    merit = changed_data[:merit_object]
    if merit.kind_of?(Merit::Score::Point)
      action = Merit::Action.find(changed_data[:merit_action_id])
      new_date = YAML.load(action.target_data).created_at
      action.update_attribute(:created_at, new_date)
      merit.update_attribute(:created_at, new_date)
    end
  end
end

def create_action(obj, index, count)
  target_model = obj.class.base_class.name.downcase
  action = Merit::Action.find_by_target_id_and_target_model_and_action_method(obj.id, target_model, 'create')
  if action.nil?
    puts "#{index}/#{count} Create merit action for #{target_model} #{obj.id}"
    obj.new_merit_action(:create)
  end
end

#puts "Destroy all merit actions"
#Merit::Action.destroy_all

#count = Person.count
#Person.all.each.with_index(1) do |person, i|
  #puts "#{i}/#{count} Remove sash from #{person.identifier}"
  #person.sash.destroy unless person.sash.nil?
#end

Merit.observers << 'ProcessObserver'

Environment.all.each do |environment|

  Merit::AppPointRules.clear
  Merit::AppBadgeRules.clear
  Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
  Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)

  article_count = environment.articles.text_articles.count
  article_index = 0
  environment.articles.text_articles.find_each do |article|
    article_index += 1
    create_action(article, article_index, article_count)

    comment_count = article.comments.count
    article.comments.each.with_index(1) do |comment, i|
      create_action(comment, i, comment_count)
    end

    followed_articles_count = article.article_followers.count
    article.article_followers.each_with_index do |af, i|
      create_action(af, i, followed_articles_count)
    end
  end

  people_count = environment.people.count
  environment.people.each.with_index(1) do |person, person_index|
    create_action(person, person_index, people_count)

    vote_count = person.votes.count
    person.votes.each.with_index(1) do |vote, vote_index|
      create_action(vote, vote_index, vote_count)
    end

    friendship_count = person.friends.count
    person.friends.each_with_index do |friend, index|
      create_action(friend, index, friendship_count)
    end
  end

  environment.people.each.with_index(1) do |person, person_index|
    puts "Updating #{person.identifier} level"
    person.update_attribute(:level, person.gamification_plugin_calculate_level)
  end

end
