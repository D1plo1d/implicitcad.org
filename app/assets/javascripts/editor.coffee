#= require stl_viewer
$ ->
  $editor = $(".editor")

  # anything after the ? is interpretted as a extopenscad script (if present)
  location_array = window.location.toString().split("?")
  content = if ( location_array.length >= 2 ) then location_array[1].replace(/%20/g, " ").replace(/\\n/g, "\n") else $editor.html()

  $editor.html("")
  codeMirror = CodeMirror $editor[0],
    value: content
    mode:  "clike"
    lineNumbers: true

  console.log $(".io-bar").ioBar
  $(".io-bar").ioBar
    app: "extopenscad"
    serialize: => codeMirror.getValue()
    deserialize: (content) => codeMirror.setValue(content)
    reset:  => codeMirror.setValue("")

  # Insert the stl viewer
  $stlViewer = $(".stl-viewer").stlViewer()

  # Zoom buttons
  $(".btn-zoom-out").click => $stlViewer.stlViewer("zoom", -1)
  $(".btn-zoom-in").click => $stlViewer.stlViewer("zoom", +1)
  $(".btn-toggle-transparency").click =>
    console.log "mooo"
    $stlViewer.stlViewer("setTransparent")

  # Keyboard shortcuts (because OpenSCAD had lame keybindings)
  $keys = $(document).add("textarea")

  $keys.on "keydown", null, "F2", -> $(".io-bar").ioBar("save"); return false

  $keys.on "keydown", null, "F4", -> $(".btn-render").click(); return false
  $keys.on "keydown", null, "F5", -> $(".btn-render").click(); return false
  $keys.on "keydown", null, "F6", -> $(".btn-render").click(); return false


  # Sending the code to the server to render
  $(".btn-render").click =>
    $(".console").html("<p><span class='label label-info'>Please hold.</span> Our best server imps are now rendering your file.</p>")

    $(".stl-viewer").stlViewer("clearGeometry")

    post = $.ajax
      url: 'http://23.21.177.106:8000/render/'
      data: {source: codeMirror.getValue()}
      dataType: "jsonp"
      success: (shape, output) ->
        $(".stl-viewer").stlViewer( "loadGeometry", shape ) if shape?
        output_html = output.replace("\n", "<br/>")
        if shape?
          $(".console").append("<p>#{output_html}</p>")
        else
          $(".console").append("<p class='error'><span class='label label-important'>Error</span> #{output_html}</p>")
      error: ->
        $(".console").append "<p class='error'><span class='label label-important'>Error</span> <b>Oh no!</b> Something has gone wrong while we were rendering your file</p>"
        $(".console").append("<pre style='font-size: 5px; line-height: 5px'>       ▄██████████████▄▐█▄▄▄▄█▌\n      ██████▌▄▌▄▐▐▌███▌▀▀██▀▀\n      ████▄█▌▄▌▄▐▐▌▀███▄▄█▌\n      ▄▄▄▄▄██████████████▀</pre>")
        $(".console").append "<p class='error'>We're going to give those imps some really stern looks but in the mean time please try again or file a bug report if the problem persists.</p>"
