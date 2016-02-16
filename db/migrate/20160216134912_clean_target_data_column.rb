class CleanTargetDataColumn < ActiveRecord::Migration
  
  def up
    Merit::Action.find_each do |action|
      next if action.target_data.blank?
      obj = YAML.load(action.target_data) rescue nil
      unless obj.nil?
        action.update_attribute(:target_model, obj.class.respond_to?(:base_class) ? obj.class.base_class.name : obj.class.name)
      end
    end
    Merit::Action.update_all(target_data: nil)
  end
  
  def down
    puts "Warning: cannot restore target_data"
  end
  
end
