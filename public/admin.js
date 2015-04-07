var gamificationPluginAdmin = {

  addNewLevelRule: function() {
    var template = $('.gamification-plugin-rank-rules .template-level > div').clone();
    template.find('.level-value').text($('.gamification-plugin-rank-rules .rank-rules .items .level').length + 1);
    $('.gamification-plugin-rank-rules .rank-rules .items').append(template);
  }
}
