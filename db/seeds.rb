unless GamificationPlugin::PointsType.count
  Merit::PointRules::AVAILABLE_RULES.each do |name , setting|
    GamificationPlugin::PointsType.create! name: name.to_s, description: setting[:description]
  end
end
