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
  puts "Recreating actions for #{person.identifier} on model #{objects.name}"
  actions = Merit::Action.where(target_id: objects, target_model: objects.name.downcase, action_method: 'create')
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

puts "Cleaning up points from actions which don't exist"
Merit::Score::Point.includes(:action).find_each(batch_size: 100) do |point|
  point.destroy if point.action.nil?
end

# erase the badges spreadsheet
CSV.open( "gamification_wrong_badges.csv", 'w' ) do |csv|
  csv << ['identifier', 'missing badges', 'exceeding badges']
end
# erase the points spreadsheet
CSV.open( "gamification_points_out_expectation.csv", 'w' ) do |csv|
  csv << ['identifier', 'name', 'action', 'profile', 'category id', 'category type', 'should have', 'have']
end

Environment.all.each do |environment|
  puts "Process environment #{environment.name}"

  Merit::AppPointRules.clear
  Merit::AppBadgeRules.clear
  Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
  Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)

  group_control = YAML.load(File.read(File.join(Rails.root,'tmp','control_group.yml'))) if File.exist?(File.join(Rails.root,'tmp','control_group.yml'))
  conditions = group_control.nil? ? {} : {:identifier => group_control.map{|k,v| v['profiles']}.flatten}

  clean_profiles_file = File.join(Rails.root,'tmp','gamification_clean_profiles.yml')
  clean_profiles = YAML.load(File.read(clean_profiles_file)) if File.exist?(File.join(clean_profiles_file))
  clean_profiles = [0] if clean_profiles.nil?

  people_count = environment.people.where(conditions).where("id not in (?)",clean_profiles).count
  person_index = 0
  puts "Analising environment people"
  environment.people.where("id not in (?)",clean_profiles).find_each(:conditions => conditions) do |person|
    person_index += 1
    profile_ids = GamificationPlugin::PointsCategorization.uniq.pluck(:profile_id)
    profile_ids.keep_if { |item| group_control.keys.include?(item) } unless group_control.nil?
    profile_ids.delete nil # avoid loosing time with generic for now
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
      #puts "Proposed #{person_articles.count} times, Commented #{comments.count} times, Voted #{votes.count} times, Followed #{follows.count} times"
      #puts "Received #{votes_received.count} votes, #{comments_received.count} comments, #{follows_received.count} follows\n"

      scope_by_badge_action = {
        "articlefollower#create" => follows, "comment#create" => comments, "article#create" => person_articles, "vote#create" => votes
      }

      # ignoring user badges out of environment badges
      should_and_doesnt_have = []
      should_not_have = []
      should_have = true
      environment.gamification_plugin_badges.each do |badge|
        (badge.custom_fields || {}).each do |action, config|
          break if scope_by_badge_action[action].nil? or config[:threshold].nil?
          should_have &= scope_by_badge_action[action].count >= config[:threshold].to_i
        end
        have = person.badges.include? badge
        if should_have && !have
          should_and_doesnt_have << "#{badge.title} #{badge.level}"
        elsif should_have && !have
          should_not_have << "#{badge.title} #{badge.level}"
        end
      end
      if should_and_doesnt_have.size > 0 || should_not_have.size > 0
        CSV.open( "gamification_wrong_badges.csv", 'a' ) do |csv|
          [person.identifier, should_and_doesnt_have.join(' | '), should_not_have.join(' | ')]
        end
      end

      scope_by_type = {
        article_author: person_articles, comment_author: comments, vote_voter: votes, follower: follows,
        comment_article_author: comments_received, vote_voteable_author: votes_received, followed_article_author: follows_received
      }

      puts "Points:"
      is_profile_clean = true
      scope_by_type.each do |type, scope|
        c = GamificationPlugin::PointsCategorization.for_type(type).where(profile_id: profile_id).joins(:point_type).first
        points = calc_points c, scope
        puts "On #{c.point_type.name} it should have #{points} and have #{person.points(category: c.id.to_s)} "
        if points != person.points(category: c.id.to_s)
          recreate_actions person, scope, c.id.to_s
          points = calc_points c, scope
          if points != person.reload.points(category: c.id.to_s)
            puts "after recreating points the person has: #{person.reload.points(category: c.id.to_s)} and should have #{points}"
            # write to the spreadsheet the person points that couldn't regulate
            CSV.open( "gamification_points_out_expectation.csv", 'a' ) do |csv|
              [person.identifier, person.name, scope.first.class.base_class.name, profile_name, c.id, c.point_type.name, scope.count*c.weight, person.points(category: c.id.to_s)]
            end
            is_profile_clean = false
          else
            puts "points fixed for #{c.point_type.name}!"
          end
        end
      end
      File.open(clean_profiles_file, 'w') {|f| f.write(clean_profiles.push(person.id).to_yaml)} if is_profile_clean
      puts
    end
  end

  # update everyone's level after the whole pontuation,
  # which is much faster than on every created action
  environment.people.find_each(batch_size: 100) do |person|
    puts "Updating #{person.identifier} level\n"
    person.update_attribute(:level, person.gamification_plugin_calculate_level)
  end
end
