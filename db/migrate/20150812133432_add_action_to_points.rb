class AddActionToPoints < ActiveRecord::Migration
  def change
    change_table :merit_score_points do |t|
      t.references :action
    end
  end
end
