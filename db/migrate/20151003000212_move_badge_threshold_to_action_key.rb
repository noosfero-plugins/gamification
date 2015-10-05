class MoveBadgeThresholdToActionKey < ActiveRecord::Migration
  def up
    GamificationPlugin::Badge.all.each do |badge|
      next if Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].nil?
      Merit::BadgeRules::AVAILABLE_RULES.each do |name, settings|
        setting = settings.first
        badge.custom_fields[setting[:action]] = {threshold: badge.custom_fields[:threshold]} unless badge.custom_fields[:threshold].nil?
        badge.save
      end
    end
  end

  def down
    GamificationPlugin::Badge.all.each do |badge|
      next if Merit::BadgeRules::AVAILABLE_RULES[badge.name.to_sym].nil?
      Merit::BadgeRules::AVAILABLE_RULES.each do |name, settings|
        setting = settings.first
        badge.custom_fields[:threshold] = badge.custom_fields[setting[:action]][:threshold] unless badge.custom_fields[setting[:action]][:threshold].nil?
        badge.save
      end
    end
  end
end
