class GamificationPlugin::API < Grape::API

  resource :gamification_plugin do

    get 'badges' do
      environment.gamification_plugin_badges.group(:name).count
    end

    resource :my do 
      get 'badges' do
        authenticate!
        present current_person.badges
      end

      get 'level' do
        authenticate!
        {:level => current_person.level, :percent => current_person.gamification_plugin_level_percent}
      end
    end

    resource :people do
      get ':id/badges' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        present person.badges
      end

      get ':id/level' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        {:level => person.level, :percent => person.gamification_plugin_level_percent}
      end

    end
  end
end

