class GamificationPluginPointsController < PluginAdminController

  def index
    @categories = GamificationPlugin::PointsCategorization.grouped_profiles
  end

  def create
    if params[:identifier].blank?
      profile_id = nil
    else
      profile = Profile.where identifier: params[:identifier]
      profile = profile.first
      if profile.nil?
        flash[:notice] = _("Can't find a profile with the given identifier")
        redirect_to action: :index
        return
      end
      profile_id = profile.id
    end

  	GamificationPlugin::PointsType.all.each do |pType|
  	  GamificationPlugin::PointsCategorization.create point_type_id: pType.id, profile_id: profile_id, weight: 0
  	end

  	redirect_to action: :edit, id: profile_id
  end

  def edit
	unless params[:gamification_plugin_points_categorizations].blank?
	  params[:gamification_plugin_points_categorizations].each do |id, category|
	  	GamificationPlugin::PointsCategorization.where(id: id).update_all(weight: category[:weight])
	  end
	  redirect_to action: :index
	end
  	@profile = Profile.find params[:id] unless params[:id].nil?
  	@categories = GamificationPlugin::PointsCategorization.where(profile_id: params[:id])
  end

  def destroy
    GamificationPlugin::PointsCategorization.where(profile_id: params[:id]).destroy_all
    redirect_to action: :index
  end
end
