module GamificationPlugin::DashboardHelper

  def level_chart(target)

    content_tag(:div, :class => "level pie-chart", 'data-percent' => @target.gamification_plugin_level_percent) do
      content_tag :span, @target.level, :class => 'level-value'
    end
  end

  def score_point_class(point)
    point.num_points > 0 ? 'positive' : 'negative'
  end

  def score_point_category(point)
    point = GamificationPlugin::PointsType.where(id: point.score.category).first
    point.nil? ? '' : point.description
  end

  def score_point_target_link(point, text)
    url = Merit::PointRules.target_url(point)
    url.present? ? link_to(text, url) : text
  end

  def ranking(target, from_date=nil, limit=10)
    # FIXME move these queries to profile model
    ranking = Profile.select('profiles.*, sum(num_points) as gamification_points, ROW_NUMBER() OVER(order by sum(num_points) DESC) as gamification_position').joins(:sash => {:scores => :score_points}).where(:type => target.class).order('sum(num_points) DESC').group('profiles.id')
    ranking = ranking.where("merit_score_points.created_at >= ?", from_date) if from_date.present?
    target_ranking = Profile.from("(#{ranking.to_sql}) profiles").where('profiles.id' => target.id).first

    context_ranking = []
    target_position = target_ranking.present? ? target_ranking.gamification_position.to_i : 0
    if target_position > limit
      context_limit = limit/2
      context_ranking = ranking.offset(target_position - 1 - context_limit/2).limit(context_limit)
      limit = limit - context_limit
    end
    ranking = ranking.limit(limit)

    render(:partial => 'gamification/ranking', :locals => {:ranking => ranking, :target_ranking => target_ranking}) +
    (context_ranking.blank? ? '' : render(:partial => 'gamification/ranking', :locals => {:ranking => context_ranking, :target_ranking => target_ranking, :ranking_class => 'context'}))
  end

  def badges_title(owner)
    return _('Badges for %s' % owner.name) if owner.kind_of?(Organization)
    _('Badges')
  end

  def grouped_badges
    environment.gamification_plugin_badges.all.group_by(&:owner).sort do |a, b|
      return -1 if a.first.kind_of?(Environment)
      a.first.name <=> b.first.name
    end
  end

end
