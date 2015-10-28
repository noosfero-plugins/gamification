module Merit

  class RankObserver
    def update(changed_data)
      merit = changed_data[:merit_object]
      if merit.kind_of?(Merit::Score::Point)
        profile = merit.score.sash.profile
        profile.update_column(:level, profile.gamification_plugin_calculate_level) if profile.present?
      end
    end
  end

end
