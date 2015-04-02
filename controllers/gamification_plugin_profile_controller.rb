class GamificationPluginProfileController < ProfileController

  def info
    @target = profile
    render 'gamification/info'
  end

end
