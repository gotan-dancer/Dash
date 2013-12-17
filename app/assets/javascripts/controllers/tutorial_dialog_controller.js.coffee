window.TutorialDialogController = class extends BaseController
  className: 'tutorial dialog'

  @show: (level)->
    @controller ?= new @()
    @controller.show(level)

  constructor: ->
    super

    @overlay = $("<div class='dialog_overlay'></div>")

  show: (@level)->
    @.setupEventListeners()

    @el.css(opacity: 0).appendTo('#game_screen')

    @.render()

    @overlay.appendTo('#game')

    @el.fadeTo(400, 1)

    @visible = true

    @level.timer.pause()

  close: ->
    @.unbindEventListeners()

    @overlay.detach()
    @el.detach()

    @visible = false

    @level.timer.resume()

  render: ->
    @html(
      @.renderTemplate('tutorial_dialog')
    )

  setupEventListeners: ->
    @el.on('click', '.close, .start', @.onCloseClick)

    $(document).on('keydown', @.onKeyDown)

  unbindEventListeners: ->
    @el.off('click', '.close, .start', @.onCloseClick)

    $(document).off('keydown', @.onKeyDown)

  onCloseClick: =>
    @.close()

  onKeyDown: (e)=>
    if e.keyCode == 27
      @.onClose()