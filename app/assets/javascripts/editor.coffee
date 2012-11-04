#= require stl_viewer
$ ->
  $editor = $(".editor")

  # anything after the ? is interpretted as a extopenscad script (if present)
  location_array = window.location.toString().split("?")
  content = if ( location_array.length >= 2 ) then location_array[1].replace(/%20/g, " ").replace(/\\n/g, "\n") else $editor.html()

  $editor.html("")

  wordlist = (str) ->
    obj = {}
    words = str.split " "
    obj[word] = true for word in words
    obj

  CodeMirror.defineMIME "text/x-extopenscad",
    name: "clike"
    keywords: wordlist("circle for if else while module " + 
                    "circle square polygon " + 
                    "sphere cube cylinder " + 
                    "union difference intersection " + 
                    "translate scale rotate " + 
                    "linear_extrude rotate_extrude " +
                    "pack shell" )
    blockKeywords: wordlist "else for if module"
    atoms: wordlist "null true false" 

  codeMirror = CodeMirror $editor[0],
    value: content
    mode:  "text/x-extopenscad"
    lineNumbers: true

  console.log $(".io-bar").ioBar
  $(".io-bar").ioBar
    app: "extopenscad"
    serialize: => codeMirror.getValue()
    deserialize: (content) => codeMirror.setValue(content)
    reset:  => codeMirror.setValue("")

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

  render_and_load = -> 
    $(".console").html("<p><span class='label label-info'>Please hold.</span> Our best server imps are now rendering your file.</p>")

    $(".stl-viewer").stlViewer("clearGeometry")

    post = $.ajax
      url: 'http://23.21.177.106:8000/render/'
      data: {source: codeMirror.getValue()}
      dataType: "jsonp"
      success: (response) ->
        console.log response
        [shape, output] = response
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

  $(".download-STL").click => $.ajax
      url: 'http://23.21.177.106:8000/render/'
      data: {source: codeMirror.getValue(), format: "STL"}
      dataType: "jsonp"
      success: (response) ->
         [shape, output] = response
         uriContent = "data:model/stl," + encodeURIComponent(shape)
         location.href = uriContent

  $(".download-SVG").click => $.ajax
      url: 'http://23.21.177.106:8000/render/'
      data: {source: codeMirror.getValue(), format: "SVG"}
      dataType: "jsonp"
      success: (response) ->
         [shape, output] = response
         uriContent = "data:model/svg," + encodeURIComponent(shape)
         location.href = uriContent

  $(".download-hacklab-laser-cutter").click => $.ajax
      url: 'http://23.21.177.106:8000/render/'
      data: {source: codeMirror.getValue(), format: "gcode/hacklab-laser"}
      dataType: "jsonp"
      success: (response) ->
         [shape, output] = response
         uriContent = "data:model/gcode," + encodeURIComponent(shape)
         location.href = uriContent

  # Insert the stl viewer
  # DO THIS LAST -- it may fail, and we want the other things set up.
  $stlViewer = $(".stl-viewer").stlViewer()
  # Sending the code to the server to render
  $(".btn-render").click => render_and_load()
   
  $(window).load => do render_and_load()  if content.length > 2

