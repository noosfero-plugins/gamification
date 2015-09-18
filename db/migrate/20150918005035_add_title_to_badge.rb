class AddTitleToBadge < ActiveRecord::Migration
  def change
    add_column :gamification_plugin_badges, :title, :string
  end
end
