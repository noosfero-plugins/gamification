require_dependency 'article'

class Article

  has_merit
  has_merit_actions :user_method => :author

end
