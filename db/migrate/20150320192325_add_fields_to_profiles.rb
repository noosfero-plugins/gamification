class AddFieldsToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :sash_id, :integer
    add_column :profiles, :level,   :integer, :default => 0
  end
end
