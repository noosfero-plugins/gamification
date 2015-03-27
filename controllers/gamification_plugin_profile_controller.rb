class GamificationPluginProfileController < ProfileController

  def info
    @target = current_person
    render 'gamification/info'
  end

end
