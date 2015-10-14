require_dependency 'person'

class Person

  # TODO why this relationship doesn't exists in core?
  has_many :comments, :foreign_key => 'author_id'

  after_save { |obj| obj.new_merit_action(:update, {}) }

  def profile_completion_score_condition
    categories = []
    GamificationPlugin::PointsCategorization.for_type('profile_completion').each {|i| categories << i.id.to_s}
    self.points(category: categories) == 0 and self.is_profile_complete?
  end

  def is_profile_complete?
    !(self.name.blank? or
      (self.data[:identidade_genero].blank? and self.data[:transgenero].blank?) or
      self.data[:etnia].blank? or
      self.data[:orientacao_sexual].blank? or
      self.data[:state].blank? or
      self.data[:city].blank?)
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
