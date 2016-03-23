$ ->
  $('div.chosentree').chosentree
    width: 500
    deepLoad: true
    load: (node, callback) ->
      node.children.push
        id: value
        title: value
        has_children: true
        level: 0
        children: []
      category_list = [
        ''
        'general'
        'social'
        'economics'
        'life'
        'knowledge'
        'it'
        'fun'
        'entertainment'
        'game'
      ]
      $.each category_list, (index, value) ->
        node.children[index].children.push
          id: value
          title: value
          has_children: hasChildren
          level: 1
          children: []
        $.ajax
          url: 'http://b.hatena.ne.jp/hotentry/' + value
          type: 'GET'
          success: (res) ->
        return
      return
  $.getJSON 'collect_requests/f6991635-5cc4-4da9-b7e3-1175556288f9', (data) ->
    fa = undefined
    result = undefined
    s = undefined
    fa = undefined
    result = undefined
    s = undefined
    result = $.parseJSON(data.result)
    s = new sigma(
      renderer:
        container: document.getElementById('graph-container')
        type: 'canvas'
      settings:
        edgeColor: 'default'
        defaultEdgeColor: '#ccc'
        animationsTime: 5000
        drawLabels: false
        scalingMode: 'outside'
        batchEdgesDrawing: true
        hideEdgesOnMove: true
        sideMargin: 1)
    s.graph.read result
    s.graph.nodes().forEach (n) ->
      if !s.graph.degree(n.id)
        s.graph.dropNode n.id
      else
        n.x = Math.random()
        n.y = Math.random()
      return
    s.refresh()
    fa = sigma.layouts.configForceLink(s,
      worker: true
      autoStop: true
      background: true
      scaleRatio: 30
      gravity: 3
      easing: 'cubicInOut')
    fa.bind 'start stop', (e) ->
      console.log e.type
      document.getElementById('layout-notification').style.visibility = ''
      if e.type == 'start'
        document.getElementById('layout-notification').style.visibility = 'visible'
      return
    sigma.layouts.startForceLink()
    return
  return
