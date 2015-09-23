require_dependency 'person'

class Person

  # TODO why this relationship doesn't exists in core?
  has_many :comments, :foreign_key => 'author_id'

  def profile_completion_score_condition
    self.points(category: 'profile_completion') == 0 and self.is_profile_complete?
  end
  def is_profile_complete?
    true
  end
end
