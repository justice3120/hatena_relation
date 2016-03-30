$(function() {
  var hatenaUrl = "http://b.hatena.ne.jp/hotentry/"

  var categories = loadCategories(hatenaUrl);

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
      minEdgeSize: 0.5,
      maxEdgeSize: 2.5,
      maxNodeSize: 3,
      maxNodeSize: 30,
      sideMargin: 1,
      imageThreshold: 3
    }
  });

  $("#start-button").click(function() {
    var holdOnOption = {
      theme: "sk-cube-grid",
      message: "Processing ..."
    }
    HoldOn.open(holdOnOption);

    requestData = { collect_request: { eid_list: ["283517550"] } }
    $.post("collect_requests", requestData, function(response) {
      var collectRequestId = response.request_id
      var retryCount = 0;
      var timerId = setInterval(function() {
        $.ajax({
          url: 'collect_requests/' + collectRequestId,
          async: true,
          dataType: "json",
          success: function(data) {
            if (data.completed) {
              clearInterval(timerId);
              var result = $.parseJSON(data.result);
              drawNetwork(result);
            }
          }
        });
      }, 10 * 1000);
    });
  });

  function loadCategories(hatenaUrl) {
    var categories = []

    var holdOnOption = {
      theme: "sk-cube-grid",
      message: "Loading ..."
    }
    HoldOn.open(holdOnOption);

    $.ajax({
      url: hatenaUrl,
      type: 'GET',
      success: function(res) {
        $(res.responseText).find("#navi-category").find(".navi-link").each(function(index, categoryElement) {
          var categoryText = $(categoryElement).find('span').text();
          var categoryClass = $(categoryElement).find('a').attr("class").split('-').pop();
          categories[index] = categoryClass;
          var openButton = $("<button>").attr("type", "button").addClass("btn").addClass("btn-secondary").addClass("btn-sm").addClass("btn-open").text("+");
          var checkbox = $("<input>").attr("type", "checkbox");
          var categoryLiElement = $("<li/>").addClass('list-group-item').addClass('category').addClass(categoryClass).append(openButton).append($("<div/>").text(categoryText));
          categoryLiElement.appendTo("#category-list");
          HoldOn.close();
        });
      }
    });
    return categories;
  }

  function drawNetwork(data) {
    s.graph.clear();
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
    /*var fa = sigma.layouts.configForceLink(s, {
      worker: true,
      autoStop: true,
      background: true,
      scaleRatio: 30,
      gravity: 3,
      easing: 'cubicInOut'
    });
    fa.bind('stop', function(e) {
      HoldOn.close();
    });*/
    var fr = sigma.layouts.fruchtermanReingold.configure(s, {
      gravity: 9,
      easing: 'cubicInOut'
    });
    fr.bind('stop', function(e) {
      HoldOn.close();
    });
    //sigma.layouts.startForceLink();
    sigma.layouts.fruchtermanReingold.start(s);
  }
});
