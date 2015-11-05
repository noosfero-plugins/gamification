#!/usr/bin/env ruby
# encoding: UTF-8

#
# This script was created for ensuring all the actions observed
# by merit for pontuation was judged and pontuated accordingly
# It checks the merit_actions registers for each action(model
# create or destroy) and recreates it
#

require 'csv'

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

def recreate_actions person, objects, category
  puts "Recreating actions for #{person.identifier} on model #{objects.first.class.base_class.name}"
  actions = Merit::Action.where(target_id: objects, target_model: objects.first.class.base_class.name.downcase, action_method: 'create')
  Merit::Score::Point.where(action_id: actions).destroy_all
  actions.destroy_all
  # erase remaining points if any (can be wrong on destroy cases ?)
  person.score_points.where(score_id: Merit::Score.where(category: category)).destroy_all
  count = objects.count
  objects.each_with_index{ |obj, index| create_action(obj, index, count) }
end

def calc_points categorization, objects
  rule = Merit::PointRules::AVAILABLE_RULES[categorization.point_type.name.to_sym]
  return 0 if rule.nil?

  sum = objects.map{|o| rule[:value].respond_to?(:call) ? rule[:value].call(o) : rule[:value] }.sum
  return sum * categorization.weight
end

# avoid updating level on every action for increasing performance
Merit.observers.delete('RankObserver')

Merit.observers << 'ProcessObserver'

class Article < ActiveRecord::Base
  def self.text_article_types
    ['ProposalsDiscussionPlugin::Proposal']
  end
end

puts "Creaning up points from actions which don't exist"
Merit::Score::Point.includes(:action).find_each(batch_size: 100) do |point|
  point.destroy if point.action.nil?
end

Environment.all.each do |environment|
  puts "Process environment #{environment.name}"

  Merit::AppPointRules.clear
  Merit::AppBadgeRules.clear
  Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
  Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)

  group_control = YAML.load(File.read(File.join(Rails.root,'tmp','control_group.yml'))) if File.exist?(File.join(Rails.root,'tmp','control_group.yml'))
  conditions = group_control.nil? ? {} : {:identifier => group_control.map{|k,v| v['profiles']}.flatten}
  people_count = environment.people.where(conditions).count
  person_index = 0
  remaining_wrong_points = []
  puts "Analising environment people"
  environment.people.find_each(:conditions => conditions) do |person|
    person_index += 1
    profile_ids = GamificationPlugin::PointsCategorization.uniq.pluck(:profile_id)
    profile_ids.keep_if { |item| group_control.keys.include?(item) } unless group_control.nil?
    profile_ids.each do |profile_id|
      profile = Profile.where(id: profile_id).first
      if profile.nil?
        profile_name = 'generic'
        # person actions
        person_articles = Article.where(author_id: person.id)
        comments = Comment.where(author_id: person.id)
        votes = Vote.for_voter(person)
        follows = ArticleFollower.where(person_id: person.id)
      else
        profile_name = profile.identifier
        #person actions
        person_articles = Article.where(author_id: person.id, profile_id: profile)
        comments = Comment.where(author_id: person.id, source_id: profile.articles)
        general_votes = Vote.for_voter(person)
        votes = general_votes.where("(voteable_type = 'Article' and voteable_id in (?)) or (voteable_type = 'Comment' and voteable_id in (?))",profile.articles, Comment.where(source_type: "Article", source_id: profile.articles))
        follows = ArticleFollower.where(person_id: person.id, article_id: profile.articles)
      end
      # received actions
      comments_received = Comment.where(:source_id => person_articles)
      votes_received = Vote.where("(voteable_type = 'Article' and voteable_id in (?)) or (voteable_type = 'Comment' and voteable_id in (?))",person_articles, person.comments)
      follows_received = ArticleFollower.where(:article_id => person_articles)

      puts "#{person_index}/#{people_count} - Analising points for #{person.identifier} on #{profile_name}"
      puts "Proposed #{person_articles.count} times, Commented #{comments.count} times, Voted #{votes.count} times, Followed #{follows.count} times"
      puts "Received #{votes_received.count} votes, #{comments_received.count} comments, #{follows_received.count} follows\n"

      scope_by_type = {
        article_author: person_articles, comment_author: comments, vote_voter: votes, follower: follows,
        comment_article_author: comments_received, vote_voteable_author: votes_received, followed_article_author: follows_received
      }

      puts "Points:"
      scope_by_type.each do |type, scope|
        c = GamificationPlugin::PointsCategorization.for_type(type).where(profile_id: profile_id).joins(:point_type).first
        points = calc_points c, scope
        puts "On #{c.point_type.name} it should have #{points} and have #{person.points(category: c.id.to_s)} "
        if points != person.points(category: c.id.to_s)
          recreate_actions person, scope, c.id.to_s
          points = calc_points c, scope
          puts "after recreating points the person has: #{person.reload.points(category: c.id.to_s)} and should have #{points}"
          remaining_wrong_points << [person.identifier, person.name, scope.first.class.base_class.name, profile_name, c.id, c.point_type.name, scope.count*c.weight, person.points(category: c.id.to_s)] if points != person.points(category: c.id.to_s)
        end
      end
      puts
    end
  end

  # update everyone's level after the whole pontuation,
  # which is much faster than on every created action
  environment.people.find_each(batch_size: 100) do |person|
    puts "Updating #{person.identifier} level\n"
    person.update_attribute(:level, person.gamification_plugin_calculate_level)
  end

  # write to the spreadsheet the person points that couldn't regulate
  unless remaining_wrong_points.blank?
    CSV.open( "gamification_points_out_expectation.csv", 'w' ) do |csv|
      csv << ['identifier', 'name', 'action', 'profile', 'category id', 'category type', 'should have', 'have']
      remaining_wrong_points.each do |line|
        csv << line
      end
    end
  end

  if remaining_wrong_points.count
    puts "Finished. There was #{remaining_wrong_points.count} people/pontuation types with errors after check and fix. Please check the created spreadsheet."
  else
    puts "Finished. There was no errors after checking. \o/ Pontuation seems to be ok!"
  end
end
