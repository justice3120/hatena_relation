$(function() {
  var hatenaUrl = "http://b.hatena.ne.jp/hotentry/"
  $.ajax({
    url: hatenaUrl,
    type: 'GET',
    success: function(res) {
      $(res.responseText).find("#navi-category").find(".navi-link").each(function(index, categoryElement) {
        var categoryText = $(categoryElement).find('span').text();
        var categoryClass = $(categoryElement).find('a').attr("class");
        $("<li/>").addClass('list-group-item').addClass('category').addClass(categoryClass).removeClass('gnavi').text(categoryText).appendTo("#category-list");
      });
    }
  });
  var categoryList = ['', 'general', 'social', 'economics', 'life', 'knowledge', 'it', 'fun', 'entertainment', 'game'];
  $.each(categoryList, function(index, category) {
    $.ajax({
      url: hatenaUrl + category,
      type: 'GET',
      success: function(res) {
        res
      }
    });
  });
  $("#start-button").click(function() {
    $.getJSON('collect_requests/f6991635-5cc4-4da9-b7e3-1175556288f9', function(data) {
      var result = $.parseJSON(data.result);
      var s = new sigma({
        renderer: {
          container: document.getElementById('graph-container'),
          type: 'canvas'
        },
        settings: {
          edgeColor: 'default',
          defaultEdgeColor: '#ccc',
          animationsTime: 5000,
          drawLabels: false,
          scalingMode: 'outside',
          batchEdgesDrawing: true,
          hideEdgesOnMove: true,
          sideMargin: 1
        }
      });
      s.graph.read(result);
      s.graph.nodes().forEach(function(n) {
        if (!s.graph.degree(n.id)) {
          s.graph.dropNode(n.id);
        } else {
          n.x = Math.random();
          n.y = Math.random();
        }
      });
      s.refresh();
      var fa = sigma.layouts.configForceLink(s, {
        worker: true,
        autoStop: true,
        background: true,
        scaleRatio: 30,
        gravity: 3,
        easing: 'cubicInOut'
      });
      fa.bind('start stop', function(e) {
        console.log(e.type);
        document.getElementById('layout-notification').style.visibility = '';
        if (e.type === 'start') {
          document.getElementById('layout-notification').style.visibility = 'visible';
        }
      });
      sigma.layouts.startForceLink();
    });
  });
});
