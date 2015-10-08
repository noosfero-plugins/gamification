class MoveBadgeThresholdToActionKey < ActiveRecord::Migration
  def up
    change_table :gamification_plugin_badges do |t|
      t.change :custom_fields, :text
    end
    GamificationPlugin::Badge.all.each do |badge|
      next if Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].nil?
      Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].each do |setting|
        badge.custom_fields[setting[:action]] = {threshold: badge.custom_fields[:threshold]} unless badge.custom_fields[:threshold].nil?
        badge.save
      end
    end
  end

  def down
    GamificationPlugin::Badge.all.each do |badge|
      next if Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].nil?
      setting = Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].first
      badge.custom_fields = {threshold: badge.custom_fields.fetch(setting[:action], {}).fetch(:threshold, "")}
      badge.save
    end
    change_table :gamification_plugin_badges do |t|
      t.change :custom_fields, :string
    end
  end
end
