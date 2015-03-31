
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

  def new_badge
    if request.post?
      badge = GamificationPlugin::Badge.new(params[:badge])
      badge.owner = environment
      badge.save!
      session[:notice] = 'Settings succefully saved.'
      redirect_to :action => 'index'
    else
      render :file => 'gamification_plugin_admin/new_badge'
    end
  end

end
