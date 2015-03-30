require 'merit_badge'

module Merit
  module ControllerExtensions

    private

    def log_merit_action
      logger.warn('[merit_ext] log_merit_action from controller filter disabled')
    end

  end

  class TargetFinder
    # Accept proc in rule.to
    def other_target
      rule.to.respond_to?(:call) ? rule.to.call(base_target) : base_target.send(rule.to)
    rescue NoMethodError
      str = "[merit] NoMethodError on `#{base_target.class.name}##{rule.to}`" \
        ' (called from Merit::TargetFinder#other_target)'
      Rails.logger.warn str
    end
  end

  module ClassMethods

    def has_merit_actions(options = {})
      after_create { |obj| obj.new_merit_action(:create, options) }
      before_destroy { |obj| obj.new_merit_action(:destroy, options) }
    end

    # change to update_atribute to fix validation
    def _merit_sash_initializer
      define_method(:_sash) do
        sash || reload.sash || update_attribute(:sash, Sash.create)
        sash
      end
    end
  end

  def new_merit_action(action, options={})
    user_method = options[:user_method]
    user = user_method.nil? ? nil : user_method.respond_to?(:call) ? user_method.call(self) : self.send(user_method)

    action = Merit::Action.create!({
      :user_id => user ? user.id : nil,
      :action_method => action,
      :had_errors => self.errors.present?,
      :target_model => self.class.base_class.name.downcase,
      :target_id => self.id,
      :target_data => self.to_yaml
    })
    action.check_all_rules
  end

end
