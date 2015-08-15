class GamificationPlugin::RankingBlock < Block

  settings_items :limit, :type => :integer, :default => 5

  def self.description
    _('Gamification Ranking')
  end

  def help
    _('This block display te gamification rank.')
  end

  def self.pretty_name
    _('Gamification Ranking')
  end

  def embedable?
    true
  end

  def content(args={})
    block = self
    proc do
      render :file => 'blocks/ranking', :locals => {:block => block}
    end
  end

end
