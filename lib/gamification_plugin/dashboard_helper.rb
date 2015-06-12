module GamificationPlugin::DashboardHelper

  def level_chart(target)

    content_tag(:div, :class => "level pie-chart", 'data-percent' => @target.gamification_plugin_level_percent) do
      content_tag :span, @target.level, :class => 'level-value'
    end
  end

  def score_point_class(point)
    point.num_points > 0 ? 'positive' : 'negative'
  end

end
