def create_action(obj)
  target_model = obj.class.base_class.name.downcase
  action = Merit::Action.find_by_target_id_and_target_model_and_action_method(obj.id, target_model, 'create')
  if action.nil?
    puts "Create merit action for #{target_model} #{obj.id}"
    obj.new_merit_action(:create)
  end
end

Environment.all.each do |environment|

  Merit::AppPointRules.clear
  Merit::AppBadgeRules.clear
  Merit::AppPointRules.merge!(Merit::PointRules.new(environment).defined_rules)
  Merit::AppBadgeRules.merge!(Merit::BadgeRules.new(environment).defined_rules)

  environment.articles.each do |article|
    create_action(article)

    article.comments.each do |comment|
      create_action(comment)
    end
  end

end
