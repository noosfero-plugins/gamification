class CreateBadges < ActiveRecord::Migration
  def change
    create_table :gamification_plugin_badges do |t|
      t.string :name
      t.integer :level
      t.string :description
      t.string :custom_fields
      t.references :owner, :polymorphic => true
      t.timestamps
    end
  end
end
