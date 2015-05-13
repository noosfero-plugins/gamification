class GamificationPluginProfileController < ProfileController

  def dashboard
    @target = profile
    render 'gamification/dashboard'
  end

end
