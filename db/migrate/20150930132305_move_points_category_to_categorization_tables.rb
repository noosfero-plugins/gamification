class MovePointsCategoryToCategorizationTables < ActiveRecord::Migration
  def up
  	Merit::PointRules::AVAILABLE_RULES.each do |name, setting|
  	  type = GamificationPlugin::PointsType.create(name: name.to_s, description: setting[:description])
  	  env = Environment.default
      next if env.blank?
  	  settings = Noosfero::Plugin::Settings.new(env, GamificationPlugin)
      weight = settings.settings.fetch(:point_rules, {}).fetch(name.to_s, {}).fetch('weight', setting[:default_weight]).to_i
  	  cat = GamificationPlugin::PointsCategorization.create(point_type_id: type.id, weight: weight)
  	  Merit::Score.update_all "category = '#{cat.id}'", category: name
  	end
  end

  def down
  	GamificationPlugin::PointsCategorization.all.each do |categorization|
  	  Merit::Score.update_all "category = '#{categorization.point_type.name}'", category: categorization.id.to_s
  	  categorization.point_type.destroy
  	  categorization.destroy
  	end
  end
end
