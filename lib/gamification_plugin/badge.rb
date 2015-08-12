class GamificationPlugin::Badge < Noosfero::Plugin::ActiveRecord

  belongs_to :owner, :polymorphic => true

  has_many :badges_sash, :class_name => 'Merit::BadgesSash'

  attr_accessible :owner, :name, :description, :level, :custom_fields, :title

  serialize :custom_fields

  def threshold
    (custom_fields || {}).fetch(:threshold, '')
  end

  before_destroy :remove_badges

  def remove_badges
    Merit::BadgesSash.where(:badge_id => self.id).destroy_all
  end

  scope :notification_pending, :include => :badges_sash, :conditions => {:badges_sashes => {:notified_user => false}}

end
