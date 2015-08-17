var gamificationPlugin = {

  displayNotification: function(html) {
    var n = noty({
      text: html,
      type: 'success',
      layout: 'center',
      modal: 'true',
      theme: 'relax',
      closeWith: ['click', 'backdrop'],
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
  },
  displayLevelChart: function() {
    var chart = $('.gamification .pie-chart');
    var size = 60;
    chart.easyPieChart({lineWidth: 10, scaleColor: false, size: size, barColor: '#1EA5C5', trackColor: '#C0EEFF'});
    chart.width(size);
    chart.find('span').css('line-height', size+'px');
  }
}

jQuery(window).bind("userDataLoaded", function(event, data) {
  gamificationPlugin.displayUserInfo(data.gamification_plugin);
});

jQuery(document).ready(function($) {
  gamificationPlugin.displayLevelChart();
});
