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
#  puts "#{i}/#{count} Remove sash from #{person.identifier}"
#  person.sash.destroy unless person.sash.nil?
#end

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
  end

  environment.people.each.with_index(1) do |person, person_index|
    vote_count = person.votes.count
    person.votes.each.with_index(1) do |vote, vote_index|
      create_action(vote, vote_index, vote_count)
    end
  end

end
