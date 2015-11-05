# encoding: UTF-8

require 'csv'

group_control = YAML.load(File.read(File.join(Rails.root,'tmp','control_group.yml'))) if File.exist?(File.join(Rails.root,'tmp','control_group.yml'))


profile_ids = GamificationPlugin::PointsCategorization.select(:profile_id).group(:profile_id).map(&:profile_id)
profile_ids.keep_if { |item| group_control.keys.include?(item) } unless group_control.nil?
profile_ids.each do |profile_id|
  profile = Profile.where(id: profile_id).first
  if profile.nil?
    profile_name = 'generic'
  else
    profile_name = profile.identifier
  end

  puts "Creating spreadsheet for #{profile_name}"

  CSV.open( "ranking_gamification_for_#{profile_name}.csv", 'w' ) do |csv|
    categories = [:article_author, :comment_author, :comment_article_author, :vote_voteable_author, :vote_voter, :follower, :followed_article_author]
    categories_labels = ['autor do artigo', 'autor do comentário', 'comentário recebido no meu artigo', 'voto em meu conteúdo', 'voto realizado', 'seguir artigo', 'autor de artigo seguido']
    quantities_labels = ['quantidade de votos realizados', 'quantidade de amigos', 'votos positivos recebidos', 'votos negativos recebidos', 'quantidade de artigos', 'quantidade de comentários realizados', 'quantidade de comentários recebidos', 'quatidade de vezes que eu segui', 'quantidade de vezes que meus artigos foram seguidos']

    csv << ['identifier', 'name', 'score'] + categories_labels + quantities_labels
    conditions = group_control.nil? ? {} : {:identifier => group_control[profile_id]['profiles']}
    amount = Person.find(:all, :conditions => conditions).count
    count = 0

    Person.find_each(:conditions => conditions) do |person|
      count += 1
      gamification_categories = categories.map{ |c| GamificationPlugin::PointsCategorization.for_type(c).where(profile_id: profile_id).first}
      categories_values = gamification_categories.map{|c| person.score_points(:category => c.id.to_s).sum(:num_points)}
      if profile.nil?
        person_articles = Article.where(:author_id => person.id)
        person_up_votes = person.comments.joins(:votes).where('vote > 0').count + person_articles.joins(:votes).where('vote > 0').count
        person_down_votes = person.comments.joins(:votes).where('vote < 0').count + person_articles.joins(:votes).where('vote < 0').count
        person_comments = person.comments.count
        person_followers = (person.following_articles & person.article_followers.where(article_id: person_articles)).count
        votes = Vote.for_voter(person).count
      else
        person_articles = profile.articles.where(:author_id => person.id)
        person_up_votes = person.comments.where(:source_id => profile.articles).joins(:votes).where('vote > 0').count + person_articles.joins(:votes).where('vote > 0').count
        person_down_votes = person.comments.where(:source_id => profile.articles).joins(:votes).where('vote < 0').count + person_articles.joins(:votes).where('vote < 0').count
        person_comments = person.comments.where(:source_id => profile.articles).count
        person_followers = (person.following_articles & person.article_followers.where(article_id: profile.articles)).count
        the_votes = Vote.for_voter(person)
        votes = the_votes.where(voteable_type: 'Article', voteable_id: profile.articles).count + the_votes.where(voteable_type: 'Comment', voteable_id: Comment.where(source_type: ["ProposalsDiscussionPlugin::Proposal", "Article"], source_id: profile.articles)).count
      end
      quantities_values = [
        votes,
        person.friends.count,
        person_up_votes,
        person_down_votes,
        person_articles.count,
        person_comments,
        Comment.where(:source_id => person_articles).count,
        person_followers,
        ArticleFollower.where(:article_id => person_articles).count
      ]

      puts "Exporting '#{person.identifier}' #{count}/#{amount}"

      csv << [person.identifier, person.name, person.points] + categories_values + quantities_values
    end
  end
end
