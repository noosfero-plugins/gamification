# encoding: UTF-8

require 'csv'
CSV.open( "ranking_gamification.csv", 'w' ) do |csv|
  categories = [:article_author, :comment_author, :comment_article_author, :vote_voteable_author, :vote_voter, :follower, :followed_article_author]
  categories_labels = ['autor do artigo', 'autor do comentário', 'comentário recebido no meu artigo', 'voto em meu conteúdo', 'voto realizado', 'seguir artigo', 'autor de artigo seguido']
  quantities_labels = ['quantidade de votos realizados', 'quantidade de amigos', 'votos positivos recebidos', 'votos negativos recebidos', 'quantidade de artigos', 'quantidade de comentários realizados', 'quantidade de comentários recebidos', 'quatidade de vezes que eu segui', 'quantidade de vezes que meus artigos foram seguidos']

  csv << ['identifier', 'name', 'score'] + categories_labels + quantities_labels
  amount = Person.count
  count = 0
  Person.find_each do |person|
    count += 1 
    gamification_categories = categories.map{ |c| GamificationPlugin::PointsCategorization.for_type(c).first}
    categories_values = gamification_categories.map{|c| person.score_points(:category => c.id.to_s).sum(:num_points)}
    person_articles = Article.where(:author_id => person.id)
    puts "Exporting '#{person.identifier}' #{count}/#{amount}"

    quantities_values = [
      Vote.for_voter(person).count,
      person.friends.count,
      person.comments.joins(:votes).where('vote > 0').count + person_articles.joins(:votes).where('vote > 0').count,
      person.comments.joins(:votes).where('vote < 0').count + person_articles.joins(:votes).where('vote < 0').count,
      person_articles.text_articles.count,
      person.comments.count,
      Comment.where(:source_id => person_articles).count,
      person.following_articles.count,
      ArticleFollower.where(:article_id => person_articles).count
    ]
    csv << [person.identifier, person.name, person.points] + categories_values + quantities_values
  end
end
