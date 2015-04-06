var gamificationPlugin = {

  displayNotification: function(html) {
    var n = noty({
      text: html,
      type: 'success',
      layout: 'center',
      modal: 'true',
      theme: 'relax',
      animation: {
        open  : 'animated bounceInLeft',
        close : 'animated bounceOutLeft',
        easing: 'swing',
        speed : 500
      }
    });
  },
  displayUserInfo: function(gamificationPlugin) {
    var info = jQuery('.gamification-plugin.user-info-template').clone();
    info.find('.badges .value').text(gamificationPlugin.badges.length);
    info.find('.points .value').text(gamificationPlugin.points);
    info.find('.level .value').text(gamificationPlugin.level);
    info.insertAfter('#user .logged-in #homepage-link');
    info.show();
  }
}

jQuery(window).bind("userDataLoaded", function(event, data) {
  gamificationPlugin.displayUserInfo(data.gamification_plugin);
});
