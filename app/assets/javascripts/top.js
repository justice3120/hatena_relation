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
    var holdOnOption = {
      theme: "sk-cube-grid",
      message: "Analyzing..."
    }
    HoldOn.open(holdOnOption);

    requestData = { collect_request: { eid_list: ["283062490"] } }
    $.post("collect_requests", requestData, function(response) {
      var collectRequestId = response.request_id
      var retryCount = 0;
      var timerId = setInterval(function() {
        $.ajax({
          url: 'collect_requests/' + collectRequestId,
          async: false,
          dataType: "json",
          success: function(data) {
            if (data.completed) {
              clearInterval(timerId);
              HoldOn.close();
              var result = $.parseJSON(data.result);
              drawNetwork(result);
            }
          }
        });
      }, 10 * 1000);
    });
  });

  function drawNetwork(data) {
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
    s.graph.read(data);
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
  }
});
