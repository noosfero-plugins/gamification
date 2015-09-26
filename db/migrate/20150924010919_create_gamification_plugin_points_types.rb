class CreateGamificationPluginPointsTypes < ActiveRecord::Migration
  def change
    create_table :gamification_plugin_points_types do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
