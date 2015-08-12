module Merit

  class PointTrackObserver
    def update(changed_data)
      merit = changed_data[:merit_object]
      if merit.kind_of?(Merit::Score::Point)
        merit.update_attribute(:action_id, changed_data[:merit_action_id])
      end
    end
  end

end
