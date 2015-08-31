class GamificationPlugin::API < Grape::API

  resource :gamification_plugin do

      resource :my do 
        get 'badges' do
          present current_person.badges
        end
      end

    resource :people do
      get ':id/badges' do
        person = environment.people.visible_for_person(current_person).find_by_id(params[:id])
        return not_found! if person.blank?
        present person.badges
      end

    end
  end
end

