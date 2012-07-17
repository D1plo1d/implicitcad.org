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
  rendering_error = ->
    $(".console").append "<p class='error'><span class='label label-important'>Error</span> <b>Oh no!</b> Something has gone wrong while we were rendering your file</p>"
    $(".console").append("<pre style='font-size: 5px; line-height: 5px'>       ▄██████████████▄▐█▄▄▄▄█▌\n      ██████▌▄▌▄▐▐▌███▌▀▀██▀▀\n      ████▄█▌▄▌▄▐▐▌▀███▄▄█▌\n      ▄▄▄▄▄██████████████▀</pre>")
    $(".console").append "<p class='error'>We're going to give those imps some really stern looks but in the mean time please try again or file a bug report if the problem persists.</p>"


  $(".btn-render").click =>
    $(".console").html("<p><span class='label label-info'>Please hold.</span> Our best server imps are now rendering your file.</p>")
    post = $.post '/render', codeMirror.getValue(), "script"

    post.success (response) ->
      puts response
      # erroring out on stderr
      if response["stderr"]? and response["stderr"].trim().length > 0
        $(".console").append("<p class='error'><span class='label label-important'>Error</span> #{response["stderror"]}</p>")
        return
      # erroring out on no data
      return rendering_error() if response["data"].length == 0

      console.log response["format"]
      console.log response["stdout"]

      # displaying the console output
      $(".console").append "<p>#{response["stdout"]}</p>"

      # displaying the output in a viewer
      $(".stl-viewer").stlViewer("loadSTL", response["data"]) if response["format"] == "stl"
      if response["format"] == "THREE.Geometry"
        eval( response["data"] )
        $(".stl-viewer").stlViewer( "loadGeometry", new Shape() )

      # W00t it worked!
      $(".console").append "<p><span class='label label-success'>Success</span> Your file has rendered successfully. The server imps are very happy.</p>"

    post.error rendering_error
