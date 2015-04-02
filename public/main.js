var gamificationPlugin = {

  display_notification: function(html) {
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
  }
}
