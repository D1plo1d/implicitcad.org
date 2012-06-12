#= require stl_geometry
#= require iobar/io-bar

$.widget "ui.stlViewer", $.ui.mouse,
  options: {}

  _create: ->
    @$viewer = $(@element)

    @scene = new THREE.Scene()

    #ambient = new THREE.AmbientLight( 0x666666 )
    #@scene.add( ambient )


    directionalLight = new THREE.DirectionalLight( 0xffffff )
    directionalLight.position.set( 40, -30, 100 )
    directionalLight.target.position.set(0,0,0)
    directionalLight.shadowCameraVisible = true
    directionalLight.castShadow = true
    @scene.add( directionalLight )

    spotLight = new THREE.SpotLight(0xffffff, 2)
    spotLight.position.set( 40, -30, 100 )
    spotLight.shadowCameraNear = 0.001
    #spotLight.castShadow = true
    spotLight.shadowDarkness = 0.2
    #spotLight.shadowCameraVisible = true
    @scene.add( spotLight )

    # For debugging purposes
    #window.ambientLight = ambient
    window.dLight = directionalLight
    window.spotLight = spotLight

    #pointLight = new THREE.PointLight( 0xffffff );
    #pointLight.position.x = -1
    #pointLight.position.y = -600
    #@scene.add( pointLight );



    @setCamera("orthographic")
    #@setCamera("perspective")


    @render = @render.lazy(20) 
    @renderer = new THREE.WebGLRenderer()
    #@renderer = new THREE.CanvasRenderer()
    @renderer.setSize( @$viewer.innerWidth(), @$viewer.innerHeight() )

    @$viewer.html("").append(@renderer.domElement)

    @_initController()
    @render()
    console.log "moo? init!"


  # mode = "perspective" or "orthographic"
  setCamera: (mode) ->
    @scene.remove( @camera ) if @camera?
    console.log THREE
    [w, h] = [ @$viewer.innerWidth(), @$viewer.innerHeight() ]
    if mode == "perspective"
      @camera = new THREE.PerspectiveCamera( 75, w / h, 1, 10000 )
    else
      @camera = new THREE.OrthographicCamera( w / -2, w / 2, h / -2, h / 2, -2000, 1000 )

    @camera.position.z = 100 #TODO: auto zoom to fit loaded stls in the viewer
    @scene.add( @camera )
    @render()


  loadGeometry: (geometry) ->
    #geometry	= new THREE.TorusKnotGeometry(25, 8, 75, 20)
    @scene.remove( @mesh ) if @mesh?
    #material = new THREE.MeshLambertMaterial( { color: 0xaaccff, ambient: 0xaaccff } )
    #material = new THREE.MeshBasicMaterial( { color: 0xff0000, wireframe: true } )
    #material = new THREE.MeshPhongMaterial({ ambient: 0x050505, color: 0x5500ff, specular: 0x555555, shininess: 30 })
    #material = new THREE.MeshNormalMaterial({opacity:1,shading:THREE.SmoothShading})
    material = new THREE.MeshPhongMaterial
      ambient: 0x444444
      color: 0x8844AA
      shininess: 300
      specular: 0x33AA33
      shading: THREE.SmoothShading

    @mesh = new THREE.Mesh( geometry, material )
    #@mesh = new THREE.Mesh( geometry, new THREE.MeshNormalMaterial({opacity:1,shading:THREE.SmoothShading}) )
    @mesh.doubleSided = true
    @mesh.overdraw = true
    #@mesh.castShadow = true
    #@mesh.receiveShadow = true

    #@mesh.position.y = -20
    #@mesh.position.x = -10
    #@mesh.rotation.x = -1.57/2
    #@mesh.position.z = -100

    #@scene.add( @mesh, material )
    @scene.add(@mesh)
    # reset rotation
    @mesh.rotation.x = -3/4 * Math.PI/2
    # reset mouse drag
    @dragging = false
    @render()
    console.log "loaded geometry!"


  loadSTL: (stlString)->
    @loadGeometry new STLGeometry(stlString)


  render: ->
    @renderer.render( @scene, @camera ) if @renderer?


  zoom: (delta) ->
    multiplier = 1+Math.abs(delta)
    multiplier = ( if delta < 0 then multiplier else 1/multiplier )

    @camera.scale.x *= multiplier
    @camera.scale.y *= multiplier
    @camera.scale.z *= multiplier
    @render()


  _initController: ->
    this._mouseInit()
    @element.mousewheel _.throttle ( (a,b,c,d) => @_mouseWheel(a,b,c,d) ), 20
    # Calculates a sketch-relative position vector for mouse events accounting for translation and scaling


  _mouseWheel: (event, delta, deltaX, deltaY) ->
    # TODO: zoom!
    #@zoom( @_zoom.mouseWheelIncrement * delta )
    #console.log deltaY
    @zoom(deltaY)
    event.preventDefault()
    event.stopPropagation()
    return false


  _mouseStart: (e) ->
    @_mouse_click_pos = [e.pageX, e.pageY]
    @_rotation_click_pos = if @mesh? then [@mesh.rotation.x, @mesh.rotation.z] else [0,0]
    @_dragging = true


  _mouseStop: (e) ->
    @_dragging = false


  _mouseDrag: (e) ->
    return true unless @_dragging and @mesh?

    # Get the relative mouse delta position
    mouse_pos = [e.pageX, e.pageY]
    @_mouse_delta = ( mouse_pos[i] - @_mouse_click_pos[i] for i in [0,1] )

    @mesh.rotation.x = @_rotation_click_pos[0] + @_mouse_delta[1] / 50
    @mesh.rotation.z = @_rotation_click_pos[1] + @_mouse_delta[0] / 50
    @render()