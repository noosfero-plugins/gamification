class GamificationPlugin::Badge < Noosfero::Plugin::ActiveRecord

  belongs_to :owner, :polymorphic => true

  attr_accessible :owner, :name, :description, :level, :custom_fields

  serialize :custom_fields

  def threshold
    (custom_fields || {}).fetch(:threshold, '')
  end

end
