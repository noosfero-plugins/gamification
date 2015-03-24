require_dependency 'person'

class Person

  # TODO why this relationship doesn't exists in core?
  has_many :comments, :foreign_key => 'author_id'

end
