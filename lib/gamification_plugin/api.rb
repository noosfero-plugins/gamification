class GamificationPlugin::API < Grape::API

  resource :gamification_plugin do

      resource :my do
        get 'badges' do
          present current_person.badges
        end
        get 'level' do
          {:level => current_person.level, :percent => current_person.gamification_plugin_level_percent}
        end
        get 'points' do
          {points: current_person.points}
        end
        get 'points_by_type' do
          {points: current_person.points_by_type(params[:type]) }
        end
        get 'points_by_profile' do
          {points: current_person.points_by_profile(params[:profile]) }
        end
        get 'points_out_of_profiles' do
          {points: current_person.points_out_of_profiles }
        end

      end

    resource :people do
      get ':id/badges' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        present person.badges
      end

      get ':id/points' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {:points => person.points}
      end

      get ':id/points_by_type' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {points: person.points_by_type(params[:type]) }
      end

      get ':id/points_by_profile' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {points: person.points_by_type(params[:profile]) }
      end

      get ':id/points_out_of_profiles' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {points: person.points_out_of_profiles }
      end

      get ':id/level' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {:level => person.level, :percent => person.gamification_plugin_level_percent}
      end

    end
  end
end

