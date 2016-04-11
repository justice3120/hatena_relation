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

    var hatenaUrl = "http://b.hatena.ne.jp/hotentry"
    var today = new Date();
    $('#date').text(today.getFullYear() + '/' + (today.getMonth()+1) + '/' + today.getDate());

    loadEntries(hatenaUrl);
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

      requestData = { collect_request: { eid_list: [$('.entry.ui-selected').attr('eid')] } }
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

  function loadEntries(hatenaUrl) {
    var holdOnOption = {
      theme: "sk-cube-grid",
      message: "Loading ..."
    }
    HoldOn.open(holdOnOption);

    $.ajax({
      url: hatenaUrl,
      type: 'GET',
      success: function(res) {
        $(res.responseText).find("li.entry-unit").slice(0, 8).each(function(index, entryElement) {
          var entry = $(entryElement)
          var entryId = entry.attr('data-eid');
          var title = entry.find('a.entry-link').text();
          var category = entry.attr('class').split(' ')[1].split('-')[1];
          var bookmark = entry.find('ul.users').find('span').text();
          var bookmarkElement = $('<span class="label label-default label-pill pull-xs-right bookmark"/ >').text(bookmark);
          var entryLiElement = $("<li/>").attr('eid', entryId).addClass('list-group-item').addClass('entry').addClass(category).append($('<div class="entry-title" />').text(title)).append(bookmarkElement);
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

  function showErrorMessage(msg) {

  }
});
