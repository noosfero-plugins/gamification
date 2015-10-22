# encoding: UTF-8

require 'csv'

profile_ids = GamificationPlugin::PointsCategorization.select(:profile_id).group(:profile_id).map(&:profile_id)
profile_ids.each do |profile_id|
  profile = Profile.where(id: profile_id).first
  if profile.nil?
    profile_name = 'generic'
  else
    profile_name = profile.name
  end

  next if profile_name != 'Conferencia'
  puts "Creating spreadsheet for #{profile_name}"

  CSV.open( "ranking_gamification_for_#{profile_name}.csv", 'w' ) do |csv|
    categories = [:article_author, :comment_author, :comment_article_author, :vote_voteable_author, :vote_voter, :follower, :followed_article_author]
    categories_labels = ['autor do artigo', 'autor do comentário', 'comentário recebido no meu artigo', 'voto em meu conteúdo', 'voto realizado', 'seguir artigo', 'autor de artigo seguido']
    quantities_labels = ['quantidade de votos realizados', 'quantidade de amigos', 'votos positivos recebidos', 'votos negativos recebidos', 'quantidade de artigos', 'quantidade de comentários realizados', 'quantidade de comentários recebidos', 'quatidade de vezes que eu segui', 'quantidade de vezes que meus artigos foram seguidos']

    csv << ['identifier', 'name', 'score'] + categories_labels + quantities_labels
    amount = Person.count
    count = 0
    Person.find_each do |person|
      count += 1
      gamification_categories = categories.map{ |c| GamificationPlugin::PointsCategorization.for_type(c).where(profile_id: profile_id).first}
      categories_values = gamification_categories.map{|c| person.score_points(:category => c.id.to_s).sum(:num_points)}
      if (profile.nil?)
        person_articles = Article.where(:author_id => person.id)
      else
        person_articles = profile.articles.where(:author_id => person.id)
      end
      puts "Exporting '#{person.identifier}' #{count}/#{amount}"

      quantities_values = [
        Vote.for_voter(person).count,
        person.friends.count,
        person.comments.where(:source_id => person_articles).joins(:votes).where('vote > 0').count + person_articles.joins(:votes).where('vote > 0').count,
        person.comments.where(:source_id => person_articles).joins(:votes).where('vote < 0').count + person_articles.joins(:votes).where('vote < 0').count,
        person_articles.count,
        person.comments.where(source_id: person_articles).count,
        Comment.where(:source_id => person_articles).count,
        (person.following_articles & person.article_followers.where(article_id: person_articles)).count,
        ArticleFollower.where(:article_id => person_articles).count
      ]
      csv << [person.identifier, person.name, person.points] + categories_values + quantities_values
    end
  end
end
