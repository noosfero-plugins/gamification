require_dependency 'merit/badge'

module Merit

  # Delegate find methods to GamificationPlugin::Badge
  class Badge
    class << self
      [:find_by_name_and_level, :find].each do |method|
        delegate method, :to => 'GamificationPlugin::Badge'
      end
    end
  end

end
