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
    begin
      obj.new_merit_action(:create)
    rescue Exception => e
      puts "Could not be create: #{e.message}"
    end
  end
end

#puts "Destroy all merit actions"
#Merit::Action.destroy_all
#
#count = Person.count
#Person.all.each.with_index(1) do |person, i|
#  puts "#{i}/#{count} Remove sash from #{person.identifier}"
#  person.sash.destroy unless person.sash.nil?
#end

# avoid updating level on every action for increasing performance
Merit.observers.delete('RankObserver')

Merit.observers << 'ProcessObserver'

class Article < ActiveRecord::Base
  def self.text_article_types
#   ['TextArticle', 'TextileArticle', 'TinyMceArticle', 'ProposalsDiscussionPlugin::Proposal']
    ['ProposalsDiscussionPlugin::Proposal']
  end
end

Environment.all.each do |environment|
  puts "Process environment #{environment.name}"

  Merit::AppPointRules.clear
  Merit::AppBadgeRules.clear
  Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
  Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)

  article_count = environment.articles.where(:type => Article.text_article_types).count
  article_index = 0

  puts "Amount of articles '#{article_count}'"
  environment.articles.includes(:comments).where(:type => Article.text_article_types).find_each(batch_size: 100) do |article|
    article_index += 1
    puts "Analising article #{article_index} of #{article_count}"
    create_action(article, article_index, article_count)

    comment_count = article.comments.count
    article.comments.each.with_index(1) do |comment, i|
      puts "Analising comments of article '#{article.id}': comment #{i} of #{comment_count}"
      create_action(comment, i, comment_count)
    end

    followed_articles_count = article.article_followers.count
    article.article_followers.each.with_index(1) do |af, i|
      puts "Analising follow of article '#{article.id}': follow #{i} of #{followed_articles_count}"
      create_action(af, i, followed_articles_count)
    end
  end

  group_control = YAML.load(File.read(File.join(Rails.root,'tmp','control_group.yml'))) if File.exist?(File.join(Rails.root,'tmp','control_group.yml'))
  conditions = group_control.nil? ? {} : {:identifier => group_control.map{|k,v| v['profiles']}.flatten}
  people_count = environment.people.where(conditions).count
  person_index = 0
  puts "Analising environment people"
  environment.people.find_each(:conditions => conditions) do |person|
    person_index += 1
    puts "Analising person #{person_index} of #{people_count}"
    create_action(person, person_index, people_count)

    vote_count = person.votes.count
    person.votes.each.with_index(1) do |vote, vote_index|
      puts "Analising votes #{vote_index} of #{vote_count}"
      create_action(vote, vote_index, vote_count)
    end

    friendship_count = person.friends.count
    person.friends.each.with_index(1) do |friend, index|
      puts "Analising friends #{index} of #{friendship_count}"
      create_action(friend, index, friendship_count)
    end
  end

  amount = environment.people.count
  environment.people.each.with_index(1) do |person, person_index|
    puts "Updating #{person.identifier} level #{person_index}/#{amount}"
    person.update_attribute(:level, person.gamification_plugin_calculate_level)
  end

end
