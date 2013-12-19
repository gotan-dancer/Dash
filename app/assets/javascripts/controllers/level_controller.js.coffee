#= require ./level_animator

window.LevelController = class extends BaseController
  className: 'level_screen'

  constructor: ->
    super

    @ingredients = new IngredientMap()
    @selected_ingredient = null

    @selected_position_x = -1 #
    @selected_position_y = -1 #

    @mouse_position = {x: 0, y: 0}

    @animator = new LevelAnimator(@)

    @potion = new Potion(4)

    @timer = new Timer(settings.timeLimit)

    @score = 0
    @potions_mixed = 0
    @ingredients_used = 0

  show: ->
    @.setupEventListeners()

    @.render()

  setupEventListeners: ->
    $(document).on('keydown', @.onKeyDown)
    $(document).on('keyup', @.onKeyUp)

    @el.on('mousedown touchstart', 'canvas', @.onMouseDown)
    @el.on('mousemove touchmove', 'canvas', @.onMouseMove)
    @el.on('mouseup touchend mouseleave', 'canvas', @.onMouseUp)

    @el.on('click', '.tutorial', @.onTutorialClick)

  updateEventOffsets: (e)->
    return if e.offsetX and e.offsetY

    e.offsetX = e.originalEvent.layerX
    e.offsetY = e.originalEvent.layerY

  render: ->
    @animator.deactivate()

    @el.appendTo('#game')

    @el.append('<button class="tutorial">How To Play</button>')

    @animator.activate()

  updateState: ->
    if @timer.currentValue() == 0
      @.finish()

  onMouseDown: (e)=>
    e.preventDefault()

    return if @animator.isBlockingAnimationInProgress()

    if e.type == 'mousedown'
      @.updateEventOffsets(e)
    else
      @.onMouseMove(e)

    if @selected_ingredient
      @.onMouseUp(e)
    else
      position = @animator.mousePositionToIngredientPosition(@mouse_position)

      @selected_ingredient = @ingredients.get(position.x, position.y)
      @selected_ingredient.toggleSelection()

      @selected_position_x = position.x # !
      @selected_position_y = position.y # !
  onMouseMove: (e)=>
    e.preventDefault()

    if e.type == 'mousemove'
      @.updateEventOffsets(e)

      @mouse_position.x = e.offsetX
      @mouse_position.y = e.offsetY
    else
      @mouse_position.x = e.originalEvent.layerX
      @mouse_position.y = e.originalEvent.layerY

  onMouseUp: (e)=>
    @.updateEventOffsets(e)

    e.preventDefault()

    return unless @selected_ingredient

    if @ingredients.isMatch(@selected_position_x,@selected_position_y) 
      @.swapIngredients(@selected_ingredient) 

    @selected_ingredient.toggleSelection()

    @selected_ingredient = null

  onTutorialClick: (e)=>
    e.preventDefault()

    TutorialDialogController.show(@)

  finish: ->
    @animator.deactivate()

    FinishDialogController.show(@)

  swapIngredients: (ingredient1) -> 

    @animator.animateIngredientSwap(ingredient1)

    sounds.playSound('swap')

  checkMatches: ->
    @exploding = @ingredients.getExplodingIngredients(@selected_position_x,@selected_position_y) # !

    return if @exploding.length == 0

    sounds.playSound('explode')

    for ingredient in @exploding
      ingredient.exploding = true

    @animator.animateExplosion(@exploding)

    @score += @ingredients.calculateExplodingScore()

    @ingredients_used += @exploding.length

  checkAffected: ->
    for ingredient in @exploding
      ingredient.exploding = false

    collected = @potion.checkCollectedIngredients(@exploding)

    @animator.animateCollected(collected)

    affected = @ingredients.checkAffectedIngredients(@exploding)

    @animator.animateAffected(affected)

    @exploding = null

  updatePotion: ->
    return unless @potion.isComplete()

    sounds.playSound('potion')

    @potion = new Potion(4)

    @timer.increment(settings.timeBonus)

    @score += settings.scores.potion
    @potions_mixed += 1

  onSwapAnimationFinished: ->
    @.checkMatches()

  onExplosionAnimationFinished: ->
    @.checkAffected()
    @.updatePotion()

  onAffectedAnimationFinished: ->
     @.checkMatches()
