class GamificationPluginBadgesController < PluginAdminController

  def index
    @gamification_plugin_badges = environment.gamification_plugin_badges.group_by(&:owner)
  end

  def show
    @gamification_plugin_badge = environment.gamification_plugin_badges.find(params[:id])
  end

  def new
    @gamification_plugin_badge = GamificationPlugin::Badge.new
  end

  def edit
    @gamification_plugin_badge = environment.gamification_plugin_badges.find(params[:id])
  end

  def create
    owner_id = params[:gamification_plugin_badge].delete(:owner_id)
    @gamification_plugin_badge = GamificationPlugin::Badge.new(params[:gamification_plugin_badge])
    if owner_id.present?
      @gamification_plugin_badge.owner = environment.organizations.find(owner_id)
    else
      @gamification_plugin_badge.owner = environment
    end

    if @gamification_plugin_badge.save
      session[:notice] = _('Badge was successfully created.')
      redirect_to :action => :index
    else
      render action: "new"
    end
  end

  def update
    @gamification_plugin_badge = environment.gamification_plugin_badges.find(params[:id])

    # FIXME avoid code duplication
    owner_id = params[:gamification_plugin_badge].delete(:owner_id)
    if owner_id.present?
      @gamification_plugin_badge.owner = environment.organizations.find(owner_id)
    else
      @gamification_plugin_badge.owner = environment
    end

    if @gamification_plugin_badge.update_attributes(params[:gamification_plugin_badge])
      session[:notice] = _('Badge was successfully updated.')
      redirect_to :action => :index
    else
      render action: "edit"
    end
  end

  def search_owners
    render :text => prepare_to_token_input(environment.organizations).to_json
  end

  def destroy
    @gamification_plugin_badge = environment.gamification_plugin_badges.find(params[:id])
    @gamification_plugin_badge.destroy

    redirect_to :action => :index
  end
end
