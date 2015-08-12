# encoding: UTF-8

require 'csv'
CSV.open( "ranking_gamification.csv", 'w' ) do |csv|
  categories = [:article_author, :comment_author, :comment_article_author, :vote_voteable_author, :vote_voter]
  categories_labels = ['autor do artigo', 'autor do comentário', 'comentário recebido no meu artigo', 'voto em meu conteúdo', 'voto realizado']
  quantities_labels = ['quantidade de votos realizados', 'quantidade de amigos', 'votos positivos recebidos', 'votos negativos recebidos', 'quantidade de artigos', 'quantidade de comentários realizados', 'quantidade de comentários recebidos']

  csv << ['identifier', 'name', 'score'] + categories_labels + quantities_labels
  Person.find_each do |person|
    categories_values = categories.map {|c| person.score_points(category: c).sum(:num_points)}
    person_articles = Article.where(:author_id => person.id)

    quantities_values = [
      Vote.for_voter(person).count,
      person.friends.count,
      person.comments.joins(:votes).where('vote > 0').count + person_articles.joins(:votes).where('vote > 0').count,
      person.comments.joins(:votes).where('vote < 0').count + person_articles.joins(:votes).where('vote < 0').count,
      person_articles.text_articles.count,
      person.comments.count,
      Comment.where(:source_id => person_articles).count
    ]
    csv << [person.identifier, person.name, person.points] + categories_values + quantities_values
  end
end
