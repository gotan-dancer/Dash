window.FinishDialogController = class extends BaseController
  className: 'finish dialog'

  @show: (level)->
    @controller ?= new @()

    name = localStorage.getItem('name')

    if not name or /^\s*$/.test(name)
      @controller.show(level, false)
    else
      $.post('/scores', score: {name: name, value: level.score}, (response)=>
        @controller.show(level, true, response.scores)
      )


  constructor: ->
    super

    @overlay = $("<div class='dialog_overlay'></div>")

  show: (@level, @stored, @scores)->
    @.setupEventListeners()

    @el.css(opacity: 0).appendTo('#game_screen')

    @.render()

    @overlay.appendTo('#game')

    @el.fadeTo(400, 1)

    @visible = true

  close: ->
    @.unbindEventListeners()

    @overlay.detach()
    @el.detach()

    @visible = false

    document.location = document.location

  render: ->
    @html(
      @.renderTemplate('finish_dialog')
    )

  setupEventListeners: ->
    @el.on('click', '.replay', @.onCloseClick)
    @el.on('click', '.save', @.onSaveClick)

    $(document).on('keydown', @.onKeyDown)

  unbindEventListeners: ->
    @el.off('click', '.replay', @.onCloseClick)
    @el.off('click', '.save', @.onSaveClick)

    $(document).off('keydown', @.onKeyDown)

  onCloseClick: =>
    @.close()

  onKeyDown: (e)=>
    if document.activeElement == $('input#name')[0] and e.keyCode == 13
      @.onSaveClick(e)

  onSaveClick: (e)=>
    e.preventDefault()

    localStorage.setItem('name', $('input#name').val())

    @.constructor.show(@level)