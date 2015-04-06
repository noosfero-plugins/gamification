
class GamificationPluginAdminController < PluginAdminController

  before_filter :load_settings

  def points
    if save_settings
      render :file => 'gamification_plugin_admin/index'
    else
      render :file => 'gamification_plugin_admin/points'
    end
  end

  protected

  def save_settings
    return false unless request.post?
    @settings.save!
    session[:notice] = 'Settings succefully saved.'
    true
  end

  def load_settings
    settings = params[:settings] || {}
    @settings = Noosfero::Plugin::Settings.new(environment, GamificationPlugin, settings)
  end

end
