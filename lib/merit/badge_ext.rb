require_dependency 'merit/badge'

module Merit

  # Delegate find methods to GamificationPlugin::Badge
  class Badge
    class << self
      delegate :find_by_name_and_level, :to => 'GamificationPlugin::Badge'
      delegate :find, :to => 'GamificationPlugin::Badge'
    end
  end

end
