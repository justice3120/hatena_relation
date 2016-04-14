$(function() {
  inithializeSideMenu();
  var s = inithializeSigma();
  inithializeStartButton();

  function inithializeSideMenu() {
    $("#entry-list").selectable({
      stop: function(e, ui) {
        $(".ui-selected:first", this).each(function() {
          $(this).siblings().removeClass("ui-selected");
        });
      }
    });

    var today = new Date();
    var y = today.getFullYear();
    var m = ('0' +(today.getMonth() + 1)).slice(-2);
    var d = ('0' + today.getDate()).slice(-2);

    $('#date').text(y + '/' + m + '/' + d);

    loadEntries(y + m + d);
  }

  function inithializeSigma() {
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
    return s;
  }

  function inithializeStartButton() {
    $("#start-button").click(function() {
      var holdOnOption = {
        theme: "sk-cube-grid",
        message: "Processing ..."
      }
      HoldOn.open(holdOnOption);

      requestData = { collect_request: { entry_id: $('.entry.ui-selected').attr('eid') } }
      $.post("collect_requests", requestData, function(response) {
        var collectRequestId = response.request_id
        var timerId = setInterval(function() {
          $.ajax({
            url: 'collect_requests/' + collectRequestId,
            async: true,
            dataType: "json",
            success: function(data) {
              if (data.status == "completed") {
                clearInterval(timerId);
                var result = $.parseJSON(data.result);
                drawNetwork(result);
              } else if (data.status == "failed") {
                clearInterval(timerId);
                var msg = "処理が失敗しました";
                HoldOn.close();
                showErrorMessage(msg);
              }
            }
          });
        }, 10 * 1000);
      });
    });
  }

  function loadEntries(date) {
    var holdOnOption = {
      theme: "sk-cube-grid",
      message: "Loading ..."
    }
    HoldOn.open(holdOnOption);

    $.ajax({
      url: 'hotentries/' + date,
      type: 'GET',
      dataType: "json",
      success: function(entries) {
        $.each(entries.slice(0, 8), function(index, e) {
          var bookmarkElement = $('<span class="label label-default label-pill pull-xs-right bookmark"/ >').text(e.bookmarkCount);
          var entryLiElement = $("<li/>").attr('eid', e.id).addClass('list-group-item').addClass('entry').addClass(e.category).append($('<div class="entry-title" />').text(e.title)).append(bookmarkElement);
          if (index == 0) {
            entryLiElement.addClass('ui-selected');
          }
          entryLiElement.appendTo("#entry-list");
        });
        HoldOn.close();
      }
    });
  }

  function drawNetwork(data) {
    var colors = []
    s.graph.clear();
    s.graph.read(data);
    sigma.plugins.louvain(s.graph);
    s.graph.nodes().forEach(function(n) {
      if (!s.graph.degree(n.id)) {
        s.graph.dropNode(n.id);
      } else {
        n.x = Math.random();
        n.y = Math.random();
        if (colors[n._louvain] == null) {
          colors[n._louvain] = tinycolor.random();
        }
        n.color = colors[n._louvain].toHexString();
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

  function showErrorMessage(msg) {

  }
});
