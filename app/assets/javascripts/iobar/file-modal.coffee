$.widget "ui.fileModal", 
  options: {template: ""}
  $lastSelectedItem: null

  _create: ->
    # lazy template compiling
    template = "_#{@options.template.camelize(false)}Template"
    $.ui.fileModal.prototype[template] ?= Handlebars.compile $("##{@options.template}-modal-template").html()

    # Setting up the modal
    @$modal = $(@element)
    @$modal.addClass( "modal file-modal" ).html( this[template](files: @options.files) ).modal()
    @$modal.one "hidden", => @_hidden()

    # caching some dom references
    @$list = @$modal.find(".file-list")
    @$input = @$modal.find(".file-name-input")

    # Selecting a file from the list
    @$list.on "click", "li:not(.nav-header)", (e) => @_clickListItem(e)

    # Finishing the transaction or displaying an error
    @_clickPrimaryBtn = $.proxy(@_clickPrimaryBtn, this)
    @$modal.on "click", ".modal-footer .btn-primary", @_clickPrimaryBtn
    $(document).on "keyup", null, "return", @_clickPrimaryBtn

    $(document).on "cadfilesdeleted", (e) =>
      for name in e.fileNames
        @_$items().filter( "[data-file-name='#{name}']" ).remove()


  _clickListItem: (e) ->
    $item = $(e.currentTarget)
    # ctrl + click adds the item to the current selection
    if e.ctrlKey
      $item.toggleClass("active")
      @$lastSelectedItem = $item
      return true

    @$list.find("li").not($item).removeClass("active")
    # shift click clears the previous selection and selects each item from the previously selected
    # item to the clicked item
    if e.shiftKey
      inRange = false
      $allItems = @_$items()
      $ends = @$lastSelectedItem.add($item)
      $selected = $allItems.each (i, element) =>
        $element = $(element)
        if $item.is($element) or @$lastSelectedItem.is($element)
          inRange = !(inRange)
          $element.addClass("active")
        $element.addClass("active") if inRange
        return true

    @$lastSelectedItem = $item
    $item.addClass("active")
    @$input.val $item.data("file-name") # only display the last selected item in the text input
    return true


  selectedFileNames: ->
    $.makeArray( @_$items(true) ).map (el) -> $(el).data("file-name")


  _$items: (active = false) -> @$list.find( "li:not(.nav-header)#{if active then ".active" else ""}" )

  _clickPrimaryBtn: (e) ->
    console.log "click primary"
    filename = @$modal.find(".file-name-input").val()
    return false unless filename?
    # hide the modal and trigger the modal's post-file-selection functionality
    @$modal.modal("hide").trigger $.Event("fileselected", fileName: filename)
    return true


  destroy: -> @$modal.modal("hide")


  # destroy the file modal after it is hidden
  _hidden: ->
    console.log "hidden"
    $(document).off "keyup", null, "return", @_clickPrimaryBtn
    $.Widget.prototype.destroy.call(this)

