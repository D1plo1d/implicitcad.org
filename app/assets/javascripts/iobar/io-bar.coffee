#= require iobar/file-modal

# This deals with the task of importing files, exporting files, saving and loading
# It is not included in sketch because it's not really core to sketching.
$.widget "ui.ioBar",
  options:
    app: ""
    serialize: -> alert("serialize option required!")
    deserialize:  -> alert("deserialize option required!")
    reset:  -> alert("reset option required!")
    

  _create: ->
    # Store for locally saved native cad files.
    @$ioBar = $(@element)
    console.log @options
    @localFiles = Lawnchair {name: "#{@options.app}_records" }, (store) ->
      console.log "local storage initialized"
    @_initFileMenu()
    @_initDeleteButtons()
    @_initFileShortcutKeys()


  _initFileMenu: ->
    # File bar buttons
    #--------------------------------

    # File Menu Buttons
    @$ioBar.find(".file-new").click => @reset(); true
    @$ioBar.find(".file-open").click => @load(); true
    @$ioBar.find(".file-save-as").click => @_openLocalFileModal("save"); true
    @$ioBar.find(".file-save").click => @save(); true


  _initDeleteButtons: ->
    # Delete File(s) Button
    $(document).on "click", ".file-modal .btn-delete", (e) => @_openDeleteFilesModal(); true
    $(document).bind "keyup", null, "del", (e) =>
      @_openDeleteFilesModal() if $(".file-modal:visible").length > 0
      return true


  _initFileShortcutKeys: ->
    # Keyboard bindings
    $keys =$(document).add("textarea")
    $keys.on "keydown", null, "meta+s", => @save(); false
    $keys.on "keydown", null, "meta+shift+s", => @_openLocalFileModal("save"); false
    $keys.on "keydown", null, "meta+o", => @load(); false


  name: (name) ->
    # Getting the name
    return @_name if name? == false and @_name?
    # Setting the name
    throw "no file name" unless name?
    @_name = name
    return null


  # Saves the sketch to either a new file or it's existing file depending on the argument
  # save() # -> saves the sketch to it's previous location or prompts with a save as dialog for a new file
  # save("my sketch") # -> saves the sketch under the file name "my sketch"
  save: (name = @_name) ->
    if name? then @_saveToLocalDB(name) else @_openLocalFileModal("save")


  load: (name) ->
    console.log name
    if name? then @_loadFromLocalDB(name) else @_openLocalFileModal("load")


  reset: ->  @options.reset()

  _openDeleteFilesModal: ->
    @deleteFilesTemplate ?= Handlebars.compile $("#delete-files-warning-template").html()

    $modal = $(".file-modal:visible")
    fileNames = $modal.fileModal("selectedFileNames")
    # warn about the impending deletion
    $warning = $( $("<div class='modal'></div>").appendTo("body") )
    $warning.html( @deleteFilesTemplate(files: fileNames) ).modal()
    # delete the files once they confirm they want them dead
    $warning.on "click", ".btn-warning", => @_deleteLocalFiles(fileNames)


  # opens a local file modal. Specifically this opens either a save-as modal or a load modal
  _openLocalFileModal: (op) -> @fileNames (files) =>
    t = if op == "save" then "save-as" else op # the template's css name
    $("<div id ='#{t}-modal'></div>").appendTo("body") unless $("##{t}-modal").length > 0
    $("##{t}-modal").fileModal(template: t, files: files).on "fileselected", (e) =>
      console.log "moooo!!! w00t #{op} #{e.fileName}"
      this[op](e.fileName)


  _findLocalFile: (name = @name(), fn) -> @localFiles.where "record.name == '#{name}'", (file) => ( fn(file[0] || null) )

  _deleteLocalFiles: (fileNames) ->
    for name in fileNames
      console.log "deleteing #{name}"
      @_findLocalFile name, (file) => @localFiles.remove file.key, =>
        $(document).trigger $.Event("cadfilesdeleted", fileNames: [name])



  # Saves the sketch to a browser local store. Later versions may also synchronize with remote cad repositories
  _saveToLocalDB: ( name = @name() ) -> @_findLocalFile name, (previousFile) =>
    console.log "saving locally.."
    file = { name: name, data: @options.serialize() }
    # set the key if we are overwriting an existing file of the same name
    file.key = previousFile.key if previousFile?
    # save the file and update the sketch's name
    @localFiles.save file
    @name(name)
    console.log "saved."


  # Asynchronously loads the sketch from a browser local store.
  # Later versions may also allow loading from remote cad repositories
  _loadFromLocalDB: (name = @name()) -> @_findLocalFile name, (f) =>
    throw "local file does not exist: #{name}" unless f?

    console.log name
    console.log f
    @name(name)
    @options.deserialize(f.data)


  # Maybe move this out of the scope of Sketch and into jQuery.fn?
  # List all the CAD files in the browser's local store
  fileNames: (fn) -> @localFiles.all (files) =>
    console.log files
    fn (_.map files, (f) -> f.name).sort (a,b) -> a.toLowerCase().compare(b.toLowerCase())


  # Exports the sketch to the given file format and prompts the user to download it.
  # This technically works for the default file format but it's very hackish.
  download: (format=".cadprototype.yaml") ->
    # TODO: Downloadify for exported CNC-ready files and interchange formats
    $("body").downloadify
      filename: => "cadprototypeExport#{format}"
      data: => @serialize("yaml")
      onComplete: -> console.log('Your File Has Been Saved!')
      onCancel: console.log('You have cancelled the saving of this file.')
      onError: console.log('You must put something in the File Contents or there will be nothing to save!')
      swf: '/lib/media/downloadify/downloadify.swf',
      downloadImage: '/lib/media/downloadify/download.png',
      width: 100,
      height: 30,
      transparent: true,
      append: false

