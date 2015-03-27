
class GamificationPluginAdminController < PluginAdminController

  def index
    settings = params[:settings]
    settings ||= {}

    @settings = Noosfero::Plugin::Settings.new(environment, GamificationPlugin, settings)
    if request.post?
      @settings.save!
      session[:notice] = 'Settings succefully saved.'
      redirect_to :action => 'index'
    end
  end

end
