window.IngredientMap = class
  constructor: ->
    @ingredients = []

    for x in [0 .. settings.mapSize - 1]
      @ingredients[x] = []

      for y in [0 .. settings.mapSize - 1]
        @ingredients[x][y] = new Ingredient(x,y, Ingredient.randomType())

    @explode_map = []

    for x in [0 .. settings.mapSize - 1]
      @explode_map[x] = []

      for y in [0 .. settings.mapSize - 1]
        @explode_map[x][y] = false

    @animator = new LevelAnimator(@)

  clearMap: ->
    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        @explode_map[x][y] = false

  get: (x, y)->
    @ingredients[x][y]

  isMatch: (selected_position_x, selected_position_y) -> 
    @.isPurposeMatch(selected_position_x, selected_position_y)

  isCoordinateMatch: (ingredient1, ingredient2)->
    (ingredient1.x - 1 <= ingredient2.x <= ingredient1.x + 1 and ingredient1.y == ingredient2.y) or
    (ingredient1.y - 1 <= ingredient2.y <= ingredient1.y + 1 and ingredient1.x == ingredient2.x)

  isTypeMatch: (ingredient1, ingredient2)->
    ingredient1.type != ingredient2.type

  isPurposeMatch: (selected_position_x, selected_position_y) -> 
    matches1 = @.hasMatches(selected_position_x, selected_position_y)

    matches1

  hasMatches: (selected_position_x, selected_position_y) ->
    # Return matches' count
    selected_type = @ingredients[selected_position_x][selected_position_y].type

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        @explode_map[x][y] = false

    @.solve(selected_position_x, selected_position_y, selected_type)

    solve_count = 0

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        if @explode_map[x][y]
          solve_count = solve_count + 1

    solve_count

  solve: (x, y, selected_type) ->
    # Find exploding fields using recursion
    if x < 0 or x > settings.mapSize - 1 or y < 0 or y > settings.mapSize - 1
      return

    if @explode_map[x][y] == true
      return 

    if @ingredients[x][y].type != selected_type
      return
    else
      @explode_map[x][y] = true

    @.solve(x-1,y,selected_type)
    @.solve(x+1,y,selected_type)
    @.solve(x,y-1,selected_type)
    @.solve(x,y+1,selected_type)

  getExplodingIngredients: (selected_position_x, selected_position_y) ->

    result = null

    result = @explode_map if @.hasMatches(selected_position_x, selected_position_y) > 2

    result

  # checkAffectedIngredients: ->
  #   # Moving blocks down
  #   for y in [settings.mapSize - 1 .. 1]
  #     for x in [0 .. settings.mapSize - 1]
  #       affected = []
  #       if @explode_map[x][y] #
  #         for z in [y .. 1]
  #           @ingredients[x][z].type = @ingredients[x][z-1].type
  #           @explode_map[x][z] = @explode_map[x][z-1]
  #           @animator.animateAffected([@ingredients.get(x,z),1])

  #   for x in [0 .. settings.mapSize - 1]
  #     if @explode_map[x][0]
  #       @ingredients[x][0].type = Ingredient.randomType()
  #       @explode_map[x][0] = false
  #       @animator.animateAffected([@ingredients.get(x,0),1])

  calculateExplodingScore: ->
    result = 0

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        if @explode_map[x][y]
          result += 1

    result

  isCombinations: ->
    # Check combinations existing
    busy_map = []
    isCombinationsCount = 0

    for x in [0 .. settings.mapSize - 1]
      busy_map[x] = []
      for y in [0 .. settings.mapSize - 1]
        busy_map[x][y] = false

    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        if busy_map[x][y] == false
          currentCombination = null
          currentCombination = @explode_map if @.hasMatches(x,y) > 2
          if currentCombination
            # Save in busy_map
            for i in [0 .. settings.mapSize - 1]
              for j in [0 .. settings.mapSize - 1]
                if currentCombination[i][j]
                  busy_map[i][j] = currentCombination[i][j]
            # Increment count
            isCombinationsCount += 1

    isCombinationsCount

