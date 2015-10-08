require_dependency 'person'

class Person

  # TODO why this relationship doesn't exists in core?
  has_many :comments, :foreign_key => 'author_id'

  def profile_completion_score_condition
    self.points(category: 'profile_completion') == 0 and self.is_profile_complete?
  end
  def is_profile_complete?
    # FIXME: FIND OUT A WAY TO CHECK EVERY REGISTRY FIELD
    false
  end

  def points_by_type type
    categorizations = GamificationPlugin::PointsCategorization.for_type(type)
    categorizations.inject(0) {|sum, c| sum += self.points(category: c.id.to_s) }
  end

  def points_by_profile profile
    categorizations = GamificationPlugin::PointsCategorization.for_profile(profile)
    categorizations.inject(0) {|sum, c| sum += self.points(category: c.id.to_s) }
  end

  def points_out_of_profiles
    categorizations = GamificationPlugin::PointsCategorization.where(profile_id: nil)
    categorizations.inject(0) { |sum, c| sum += self.points(category: c.id.to_s) }
  end
end
