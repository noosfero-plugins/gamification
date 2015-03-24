class AddFieldsToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :sash_id, :integer
    add_column :articles, :level,   :integer, :default => 0
  end
end
