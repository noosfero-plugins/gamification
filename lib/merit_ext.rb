require 'merit/badge_ext'
require 'merit/sash'
require 'merit/badges_sash'
require 'merit/action'

module Merit

  module ControllerExtensions

    private

    def log_merit_action
      logger.warn('[merit_ext] log_merit_action from controller filter disabled')
    end

  end

  class Score
    class Point
      belongs_to :action

      def point_type
        @point_type ||= GamificationPlugin::PointsType.where(id: score.category).first
      end

      def undo_rule?
        rule = Merit::PointRules::AVAILABLE_RULES[point_type.name.to_sym]
        rule[:undo_action] == "#{action.target_model}##{action.action_method}"
      end
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

  class Action
    def target_obj
      target_model.constantize.find_by_id(target_id)
    end

    def rules_matcher
      @rules_matcher ||= ::Merit::RulesMatcher.new(target_model.downcase, action_method)
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
      :target_model => self.class.base_class.name,
      :target_id => self.id
    })
    action.check_all_rules
    action
  end

end
