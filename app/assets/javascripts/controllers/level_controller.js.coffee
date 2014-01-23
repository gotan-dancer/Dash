#= require ./level_animator

window.LevelController = class extends BaseController
  className: 'level_screen'

  constructor: ->
    super

    @ingredients = new IngredientMap()
    @selected_ingredient = null

    @selected_position_x = -1 
    @selected_position_y = -1 

    @mouse_position = {x: 0, y: 0}

    @animator = new LevelAnimator(@)

    @potion = new Potion(4)

    @timer = new Timer(settings.timeLimit)

    @score = 0
    @potions_mixed = 0
    @ingredients_used = 0

    @last_explosion = null
    @waiting = 0

    @bombingCount = 1

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

    combinationCount = 0

    if @last_explosion != null
      @waiting = @last_explosion - @timer.currentValue()

    if @waiting % 6 == 1
      combinationCount = @ingredients.isCombinations() 
      if combinationCount < 3 
        # Create good combination
        candidateMap = []

        for x in [0 .. settings.mapSize - 1]
          candidateMap[x] = []
          for y in [0 .. settings.mapSize - 1]
            candidateMap[x][y] = false

        for x in [0 .. settings.mapSize - 1]
          for y in [0 .. settings.mapSize - 1]
            if candidateMap[x][y] == false
              candidateCombination = null

              candidateCombination = @ingredients.explode_map if @ingredients.hasMatches(x,y) == 2

              if candidateCombination
                for i in [0 .. settings.mapSize - 1]
                  for j in [0 .. settings.mapSize - 1]
                    if candidateCombination[i][j]
                      candidateMap[i][j] = candidateCombination[i][j]

        addCeilMap = []

        for x in [0 .. settings.mapSize - 1]
          addCeilMap[x] = []
          for y in [0 .. settings.mapSize - 1]
            addCeilMap[x][y] = ''

        for x in [0 .. settings.mapSize - 1]
          for y in [0 .. settings.mapSize - 1]
            if candidateMap[x][y] == true
              addCeilMap[x][y-1] = @ingredients.get(x,y).type if y-1 > -1 and candidateMap[x][y-1] != true
              addCeilMap[x][y+1] = @ingredients.get(x,y).type if y+1 < settings.mapSize and candidateMap[x][y+1] != true
              addCeilMap[x-1][y] = @ingredients.get(x,y).type if x-1 > -1 and candidateMap[x-1][y] != true
              addCeilMap[x+1][y] = @ingredients.get(x,y).type if x+1 < settings.mapSize and candidateMap[x+1][y] != true
        
        randomSize = 0
        addCeilCandidate = []

        for x in [0 .. settings.mapSize - 1]
          for y in [0 .. settings.mapSize - 1]
            if addCeilMap[x][y] != ''
              addCeilCandidate[randomSize] = 9 * x + y
              randomSize += 1


        addCeilIndex = []
        for x in [0 .. 2]
          addCeilIndex[x] = -1
          addCeilIndex[x] = _.random(randomSize - 1)

        del_x = []
        del_y = []
        for k in [0 .. 2]
          del_x[k] = -1
          del_y[k] = -1
          
          del_x[k] = Math.floor(addCeilCandidate[addCeilIndex[k]] / 9)
          del_y[k] = addCeilCandidate[addCeilIndex[k]] % 9

          @ingredients.get(del_x[k],del_y[k]).type = addCeilMap[del_x[k]][del_y[k]]
          @animator.animateIngredientSwap(@ingredients.get(del_x[k],del_y[k])) 

    if @waiting % 6 == 5
      combinationCount = @ingredients.isCombinations() 
      if combinationCount != 0
        # Wait 5 seconds for max combination's lighting
        busy_map = []

        for x in [0 .. settings.mapSize - 1]
          busy_map[x] = []
          for y in [0 .. settings.mapSize - 1]
            busy_map[x][y] = false

        max = 0
        max_x = -1
        max_y = -1

        maxCombination = []

        for x in [0 .. settings.mapSize - 1]
          maxCombination[x] = []
          for y in [0 .. settings.mapSize - 1]
            maxCombination[x][y] = false

        for x in [0 .. settings.mapSize - 1]
          for y in [0 .. settings.mapSize - 1]
            if busy_map[x][y] == false
              ceilsCount = @ingredients.hasMatches(x,y)
              currentCombination = @ingredients.explode_map
              if ceilsCount > max
                max = ceilsCount
                max_x = x
                max_y = y
                for i in [0 .. settings.mapSize - 1]
                  for j in [0 .. settings.mapSize - 1]
                    maxCombination[i][j] = currentCombination[i][j]

              if currentCombination
                # Save in busy_map
                for i in [0 .. settings.mapSize - 1]
                  for j in [0 .. settings.mapSize - 1]
                    if currentCombination[i][j]
                      busy_map[i][j] = currentCombination[i][j]

        @animator.animateMaxCombination(maxCombination)
        
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

      @selected_position_x = position.x
      @selected_position_y = position.y

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

    if @ingredients.get(@selected_position_x,@selected_position_y).type == 'bomb'
      # Explosion
      @exploding = []

      for x in [0 .. settings.mapSize - 1]
        @exploding[x] = []

        for y in [0 .. settings.mapSize - 1]
          @exploding[x][y] = false

      for x in [0 .. settings.mapSize - 1]
        for y in [0 .. settings.mapSize - 1]
          if @selected_position_x == x or @selected_position_y == y
            @exploding[x][y] = true

      @animator.animateExplosion(@exploding)

      return

    if @ingredients.isMatch(@selected_position_x,@selected_position_y) > 2
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

    return if @exploding == null

    sounds.playSound('explode')

    @animator.animateExplosion(@exploding)

    @score += @ingredients.calculateExplodingScore()

    # Bomb exploding after score multiplied 25
    if Math.floor(@score / 25) == @bombingCount
      @bombingCount += 1

      bomb_x = _.random(settings.mapSize - 1)
      bomb_y = _.random(settings.mapSize - 1)

      @animator.animateBomb(bomb_x, bomb_y) #

      @ingredients.get(bomb_x,bomb_y).type = 'bomb' #

  checkAffected: ->

    affected = []
    
    for y in [settings.mapSize - 1 .. 1]
      repeat_flag = true

      # affected = []

      while repeat_flag
        for x in [0 .. settings.mapSize - 1]
          if @exploding[x][y]
            repeat_flag = true
            for z in [y .. 1]
              @ingredients.get(x,z).type = @ingredients.get(x,z-1).type
              @exploding[x][z] = @exploding[x][z-1]

              affected.push([@ingredients.get(x,z),1])

            @ingredients.get(x,0).type = Ingredient.randomType()
            @exploding[x][0] = false

            affected.push([@ingredients.get(x,0),1])

          else
            repeat_flag = false

      # @animator.animateAffected(affected)

    @animator.animateAffected(affected)

    @ingredients.clearMap()

  checkAffectedIngredients: ->
    # Moving blocks down
    affected = []

    for y in [settings.mapSize - 1 .. 1]
      for x in [0 .. settings.mapSize - 1]
        # affected = []
        if @exploding[x][y] #
          for z in [y .. 1]
            @ingredients.get(x,z).type = @ingredients.get(x,z-1).type
            @exploding[x][z] = @exploding[x][z-1]

            # if z-1 == 0
            #   @exploding[x][z-1] = false

            affected.push([@ingredients.get(x,z),1])

            # @animator.animateAffected(affected)

    for x in [0 .. settings.mapSize - 1]
      # affected = []
      if @exploding[x][0]
        @ingredients.get(x,0).type = Ingredient.randomType()
        @exploding[x][0] = false
        affected.push([@ingredients.get(x,0),1])
        # @animator.animateAffected(affected)

    @animator.animateAffected(affected)

    @ingredients.clearMap()

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
    @.checkAffected() #
    @.updatePotion()

  onAffectedAnimationFinished: ->
    @last_explosion = null
    @last_explosion = @timer.currentValue()
