var gamificationPluginAdmin = {

  addNewLevelRule: function() {
    var template = $('.gamification-plugin-rank-rules .template-level > div').clone();
    template.find('.level-value').text($('.gamification-plugin-rank-rules .rank-rules .items .level').length + 1);
    $('.gamification-plugin-rank-rules .rank-rules .items').append(template);
  },

  selectCustomFieldsOnNameChange: function() {
  	jQuery('.controller-actions').find('input').attr('disabled', 'disabled');
  	jQuery('.controller-actions').hide();
  	console.log('.name_'+jQuery('#gamification-plugin-form-badge-name').val());
  	var name = jQuery('#gamification-plugin-form-badge-name').find('option:selected').text();
  	jQuery('.name_'+name).show();
  	jQuery('.name_'+name).find('input').removeAttr('disabled');
  }

}

jQuery(function() {
  $('#gamification-plugin-form-badge-name').on('change', gamificationPluginAdmin.selectCustomFieldsOnNameChange);
  gamificationPluginAdmin.selectCustomFieldsOnNameChange();
});
