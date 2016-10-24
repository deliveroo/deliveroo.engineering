(function(window){
  var initialEmbed = function() {
      whr(window.document).ready(function(){
          whr_embed(11498, {detail: 'titles', base: 'departments', zoom: 'city'});
      });
  };

  var removeGroups = function() {
    var $groups = jQuery('#whr_embed_hook > .whr-group');

    $groups.each(function() {
      $group = jQuery(this);
      if ($group.text() == "Product Team") {
        $list = $group.next();
        $list.removeAttr("style");
        $('#careers').append($list);
      }
    });
    jQuery('#whr_embed_hook').remove();
  };

  var removeLoadingSpinner = function() {
    jQuery('#careers').removeClass('listings-loading');
  };

  var bootstrap = function () {
    initialEmbed();

    var refreshIntervalId = setInterval(function(){
      var $whrItems = jQuery('#whr_embed_hook > .whr-items');

      if ($whrItems.length) {
        removeGroups();
        removeLoadingSpinner();

        $whrItems.addClass('content-list jobs-list');

        $whrItems.find("li.whr-item").each(function() {
          var $jobItem = jQuery(this);
          var joblink = $jobItem.find('h3 a').attr('href');
          var rawApplyHtml = ('<li class="whr-apply"><a href="' + joblink + '" class="button">Apply</a></li>');

          $jobItem.find('ul.whr-info').append(rawApplyHtml);
        });
        clearInterval(refreshIntervalId);
      }
    }, 1000);
  };

  bootstrap();
})(window);
