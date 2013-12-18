#= require ./level_animator

window.LevelController = class extends BaseController
  className: 'level_screen'

  constructor: ->
    super

    @ingredients = new IngredientMap()
    @selected_ingredient = null

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

    # position = @animator.mousePositionToIngredientPosition(@mouse_position)

    # if position.x < @selected_ingredient.x
    #   clicked_ingredient = @ingredients.get(@selected_ingredient.x - 1, @selected_ingredient.y)
    # else if position.x > @selected_ingredient.x
    #   clicked_ingredient = @ingredients.get(@selected_ingredient.x + 1, @selected_ingredient.y)
    # else if position.y < @selected_ingredient.y
    #   clicked_ingredient = @ingredients.get(@selected_ingredient.x, @selected_ingredient.y - 1)
    # else if position.y > @selected_ingredient.y
    #   clicked_ingredient = @ingredients.get(@selected_ingredient.x, @selected_ingredient.y + 1)

    # return unless clicked_ingredient

    if @ingredients.isMatch(@selected_ingredient) #, clicked_ingredient)
      @.swapIngredients(@selected_ingredient) #, clicked_ingredient)

    @selected_ingredient.toggleSelection()

    @selected_ingredient = null

  onTutorialClick: (e)=>
    e.preventDefault()

    TutorialDialogController.show(@)

  finish: ->
    @animator.deactivate()

    FinishDialogController.show(@)

  swapIngredients: (ingredient1) -> #ingredient2)->
    #[ingredient1.type, ingredient2.type] = [ingredient2.type, ingredient1.type]

    @animator.animateIngredientSwap(ingredient1)#, ingredient2)

    sounds.playSound('swap')

  checkMatches: ->
    @exploding = @ingredients.getExplodingIngredients()

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
