class CreateGamificationPluginPointsCategorizations < ActiveRecord::Migration
  def change
    create_table :gamification_plugin_points_categorizations do |t|
      t.references :profile
      t.integer :point_type_id
      t.integer :weight

      t.timestamps
    end
    add_index :gamification_plugin_points_categorizations, :profile_id
    add_index :gamification_plugin_points_categorizations, :point_type_id, name: 'index_points_categorizations_on_point_type_id'
  end
end
