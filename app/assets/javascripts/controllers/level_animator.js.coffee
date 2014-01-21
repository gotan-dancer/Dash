#= require ./animator

window.LevelAnimator = class extends Animator
  ingredientSize: 55
  ingredientGridOffset: 52

  swapAnimationSpeed: 250
  explosionAnimationSpeed: 200
  affectedAnimationSpeed: 300
  collectedAnimationSpeed: 500
  combinationAnimationSpeed: 1000

  timerStyle:
    normal:
      font: 'normal 35px Tahoma'
      align: 'right'
      fill: '#fff8f3'
    expiring:
      font: 'normal 35px Tahoma'
      align: 'right'
      fill: '#ff7988'

  scoreStyle:
    font: 'normal 35px Tahoma'
    align: 'right'
    fill: '#fff8f3'


  loops: # [StartFrame, EndFrame, Speed]
   ingredient_blue:   {frames: [0,  1], speed: 0.3}
   ingredient_bomb:   {frames: [0,  1], speed: 0.3}
   ingredient_green:  {frames: [0,  1], speed: 0.3}
   ingredient_purple: {frames: [0,  1], speed: 0.3}
   ingredient_orange: {frames: [0,  1], speed: 0.3}
   ingredient_red:    {frames: [0,  1], speed: 0.3}
   ingredient_yellow: {frames: [0,  1], speed: 0.3}

  constructor: (controller)->
    super(controller)

    @background_layer = new PIXI.DisplayObjectContainer()
    @ingredient_layer = new PIXI.DisplayObjectContainer()
    @interface_layer  = new PIXI.DisplayObjectContainer()
    @max_comb_layer   = new PIXI.DisplayObjectContainer()

    @stage.addChild(@background_layer)
    @stage.addChild(@ingredient_layer)
    @stage.addChild(@interface_layer)
    @stage.addChild(@max_comb_layer)

    @ingredients = []
    @potion_components = []
    @collecting = []
    @max_comb_components = []

  prepareTextures: ->
    return unless @.loops?

    for id, animation of @.loops
      animation.textures = []

      for frame in [animation.frames[0] .. animation.frames[1]]
        animation.textures.push(
          PIXI.Texture.fromFrame("#{ id }_#{ @.zeroPad(frame, 4) }.png")
        )

  activate: ->
    return unless super

    @.addSprites()

    @.attachRendererTo(@controller.el)

  addSprites: ->
    @background_sprite = PIXI.Sprite.fromImage(preloader.paths.background)

    @background_layer.addChild(@background_sprite)

    for column, x in @controller.ingredients.ingredients
      for ingredient, y in column
        sprite = @.createIngredientSprite(ingredient)

        @ingredient_layer.addChild(sprite)

        @ingredients[x] ?= []
        @ingredients[x][y] = sprite

    # Interface

    @timer = new PIXI.Text(@controller.timer.currentValue(), @.timerStyle.normal)
    @timer.position.x = 760
    @timer.position.y = if /Firefox/.test(navigator.userAgent) then 28 else 20
    @timer.anchor.x = 1

    @interface_layer.addChild(@timer)

    @score = new PIXI.Text(@controller.score, @.scoreStyle)
    @score.position.x = 760
    @score.position.y = if /Firefox/.test(navigator.userAgent) then 143 else 135
    @score.anchor.x = 1
    @score.anchor.y = 1

    @interface_layer.addChild(@score)

    @.createPotionSprites()

    @.createBonusSlider(0) #

    @sprites_added = true

  animate: =>
    unless @paused_at
      @controller.updateState()

      if @swap_animation_started and @.isSwapAnimationFinished()
        @swap_animation_started = null

        @controller.onSwapAnimationFinished()

      if @explosion_animation_started and @.isExplosionAnimationFinished()
        @explosion_animation_started = null

        @controller.onExplosionAnimationFinished()

      if @affected_animation_started and @.isAffectedAnimationFinished()
        @affected_animation_started = null

        @controller.onAffectedAnimationFinished()

      if @collected_animation_started and @.isCollectedAnimationFinished()
        @collected_animation_started = null

      if @combination_animation_started and @.isCombinationAnimationFinished() #
        @combination_animation_started = null #

        # @controller.on

      # if @combination_animation_alpha_started and @.isCombinationAnimationAlphaFinished() #
      #   @combination_animation_alpha_started = null #

      @.updateSpriteStates()

    super

  updateSpriteStates: ->
    return unless @sprites_added

    for sprite in @ingredient_layer.children
      @.updateIngredientSprite(sprite)

    @.updateCollectedAnimationSprites()

    @timer.setText(@controller.timer.currentValue())

    if @controller.timer.currentValue() <= 10
      @timer.setStyle(@.timerStyle.expiring)
    else
      @timer.setStyle(@.timerStyle.normal)

    @score.setText(@controller.score)

    @.createBonusSlider(@controller.score) #

    for star in @max_comb_layer.children #
      @.updateInterfaceSprite(star) #

    # for sprite in @interface_layer.children #
    #   @.updateInterfaceSpriteAlpha(sprite) #

  createIngredientSprite: (ingredient)->
    sprite = new PIXI.MovieClip(@.loops["ingredient_#{ ingredient.type }"].textures)
    sprite.position.x = @.gridToScene(ingredient.x)
    sprite.position.y = @.gridToScene(ingredient.y)
    sprite.anchor.x = 0.5
    sprite.anchor.y = 0.5
    sprite.source = ingredient
    sprite

  createPotionSprites: ->
    for [type, found], index in @controller.potion.ingredients
      sprite = new PIXI.MovieClip(@.loops["ingredient_#{ type }"].textures)
      sprite.anchor.x = 1
      sprite.position.x = 608 + index * @.ingredientSize
      sprite.position.y = 215

      if found
        sprite.gotoAndStop(1)
      else
        sprite.alpha = 0.3

      sprite.source_type = type

      @potion_components.push(sprite)

      @interface_layer.addChild(sprite)

  destroyPotionSprites: ->
    for sprite in @potion_components
      @interface_layer.removeChild(sprite)

    @potion_components = []

  isMouseWithinIngredients: (position)->
    @.gridToScene(-1) < position.x < @.gridToScene(settings.mapSize) and
    @.gridToScene(-1) < position.y < @.gridToScene(settings.mapSize)

  mousePositionToIngredientPosition: (position)->
    x = Math.floor((position.x - @.ingredientGridOffset) / @.ingredientSize + 0.5)
    y = Math.floor((position.y - @.ingredientGridOffset) / @.ingredientSize + 0.5)

    {
      x: if 0 <= x < settings.mapSize then x else if x < 0 then 0 else settings.mapSize - 1
      y: if 0 <= y < settings.mapSize then y else if y < 0 then 0 else settings.mapSize - 1
    }

  animateIngredientSwap: (ingredient1) ->
    @swap_animation_started = Date.now()

    sprite1 = @ingredients[ingredient1.x][ingredient1.y]

    sprite1.swappingWith = ingredient1

  updateIngredientSprite: (sprite)->
    if sprite.swappingWith?
      if not @swap_animation_started or @.isSwapAnimationFinished()
        sprite.textures = @.loops["ingredient_#{ sprite.source.type }"].textures

        sprite.position.x = @.gridToScene(sprite.source.x)
        sprite.position.y = @.gridToScene(sprite.source.y)

        delete sprite.swappingWith
      else
        progress = (Date.now() - @swap_animation_started) / @.swapAnimationSpeed

        sprite.position.x = @.gridToScene(sprite.swappingWith.x + (1 - progress) * (sprite.source.x - sprite.swappingWith.x))
        sprite.position.y = @.gridToScene(sprite.swappingWith.y + (1 - progress) * (sprite.source.y - sprite.swappingWith.y))

    if sprite.exploding
      if not @explosion_animation_started or @.isExplosionAnimationFinished()
        sprite.scale.x = 1
        sprite.scale.y = 1

        delete sprite.exploding
      else
        progress = (Date.now() - @explosion_animation_started) / @.explosionAnimationSpeed

        sprite.scale.x = 1 - progress
        sprite.scale.y = 1 - progress

    if sprite.affected_displacement
      if not @affected_animation_started or @.isAffectedAnimationFinished()
        sprite.position.y = @.gridToScene(sprite.source.y)

        delete sprite.affected_displacement
      else
        progress = (Date.now() - @affected_animation_started) / @.affectedAnimationSpeed

        sprite.position.y = @.gridToScene(sprite.source.y - (1 - progress) * sprite.affected_displacement)

    sprite.gotoAndStop(
      if sprite.source.selected then 1 else 0
    )

  updateCollectedAnimationSprites: ->
    if not @collected_animation_started or @.isCollectedAnimationFinished()
      @.stopCollectingAnimation()
    else
      progress = (Date.now() - @collected_animation_started) / @.collectedAnimationSpeed

      for sprite in @collecting
        sprite.position.x = 700 - (700 - @.gridToScene(sprite.source.x)) * (1 - progress)
        sprite.position.y = 230 - (160 - @.gridToScene(sprite.source.y)) * (1 - progress)


  gridToScene: (coordinate)->
    @.ingredientGridOffset + coordinate * @.ingredientSize

  isSwapAnimationFinished: ->
    Date.now() - @swap_animation_started > @.swapAnimationSpeed


  animateExplosion: (ingredients)->
    @explosion_animation_started = Date.now()

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        if ingredients[x][y] == true
          @ingredients[x][y].exploding = true       

  isExplosionAnimationFinished: ->
    Date.now() - @explosion_animation_started > @.explosionAnimationSpeed


  animateAffected: (affected)->
    @affected_animation_started = Date.now()

    for [ingredient, displacement] in affected
      sprite = @ingredients[ingredient.x][ingredient.y]
      sprite.affected_displacement = displacement
      sprite.textures = @.loops["ingredient_#{ sprite.source.type }"].textures

  isAffectedAnimationFinished: ->
    Date.now() - @affected_animation_started > @.affectedAnimationSpeed


  animateCollected: (collected)->
    @.stopCollectingAnimation() if @collected_animation_started

    @collected_animation_started = Date.now()

    for ingredient in collected
      sprite = @ingredients[ingredient.x][ingredient.y]

      clone = @.createIngredientSprite(ingredient)
      clone.scale.x = 0.8
      clone.scale.y = 0.8

      @collecting.push(clone)

      @interface_layer.addChild(clone)

  isCollectedAnimationFinished: ->
    Date.now() - @collected_animation_started > @.collectedAnimationSpeed

  stopCollectingAnimation: ->
    for sprite in @collecting
      @interface_layer.removeChild(sprite)

    @collecting = []

    @.destroyPotionSprites()
    @.createPotionSprites()


  isBlockingAnimationInProgress: ->
    @swap_animation_started or @explosion_animation_started or @affected_animation_started

# -->

  createBonusSlider: (score)->
    @bonus = new PIXI.Graphics()

    @bonus.beginFill(0xFFF,1)
    @bonus.drawRect(560,300,Math.floor(score % 25)*8,50)
    @bonus.endFill()    

    @bonus.beginFill(0,1)
    @bonus.drawRect(560+Math.floor(score % 25)*8,300,200-Math.floor(score % 25)*8,50)
    @bonus.endFill()    

    @interface_layer.addChild(@bonus)

  animateBomb: (bomb_x, bomb_y) ->
    @bomb_animation_started = Date.now()

    sprite = new PIXI.MovieClip(@.loops["ingredient_bomb"].textures)
    #sprite = PIXI.Sprite.fromImage(preloader.paths.bomb)
    sprite.position.x = @.gridToScene(bomb_x)
    sprite.position.y = @.gridToScene(bomb_y)
    sprite.anchor.x = 0.5
    sprite.anchor.y = 0.5
    sprite.source = @controller.ingredients.get(bomb_x,bomb_y) #

    @ingredient_layer.addChild(sprite) #

    @ingredients[bomb_x] ?= []
    @ingredients[bomb_x][bomb_y] = sprite

  animateMaxCombination: (maxCombination) ->
    # Star's size is increasing
    @.stopCombinationAnimation() if @combination_animation_started

    @combination_animation_started = Date.now()

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        if maxCombination[x][y]

          sprite = PIXI.Sprite.fromImage(preloader.paths.star) 

          sprite.position.x = @.gridToScene(x)
          sprite.position.y = @.gridToScene(y)
          sprite.anchor.x = 0.5 
          sprite.anchor.y = 0.5

          # sprite.maxCombSize = true

          @max_comb_components.push(sprite)

          @max_comb_layer.addChild(sprite)

  stopCombinationAnimation: ->
    for sprite in @max_comb_components
      @max_comb_layer.removeChild(sprite)

    @max_comb_components = []

  isCombinationAnimationFinished: ->
    Date.now() - @combination_animation_started > @.combinationAnimationSpeed

  updateInterfaceSprite: (sprite)->
    if ((Date.now() >= @combination_animation_started) and (Date.now() - @combination_animation_started <= @.combinationAnimationSpeed / 2))
      # timer == [begin, (end - begin) / 2]
      progress = (Date.now() - @combination_animation_started) / @.combinationAnimationSpeed * 2

      sprite.scale.x = progress * 50 / 256
      sprite.scale.y = progress * 50 / 256

      sprite.alpha = 1
    else
      if (Date.now() - @combination_animation_started >= @.combinationAnimationSpeed / 2) and not @.isCombinationAnimationFinished()
        # timer == [(end - begin) / 2, end]
        progress = (Date.now() - @combination_animation_started - @.combinationAnimationSpeed / 2) / @.combinationAnimationSpeed * 2

        sprite.scale.x = 50 / 256
        sprite.scale.y = 50 / 256

        sprite.alpha = 1 - progress

# <--
