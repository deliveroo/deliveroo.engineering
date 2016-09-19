(function() {
  anchors.options = {
    placement: 'left',
    visible: 'touch',
  };
  
  anchors.add('h2, h3, h4');
  anchors.remove('div.post h3, div.guideline h3, div.author h3, aside h3, aside h4, h2.no_toc');
}).call(this);
