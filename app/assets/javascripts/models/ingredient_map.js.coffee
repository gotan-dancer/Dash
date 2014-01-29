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

  checkAffectedIngredients: (exploded)->

    affected = []

    displace = []
    for x in [0 .. settings.mapSize - 1]
      displace[x] = []
      for y in [0 .. settings.mapSize - 1]
        displace[x][y] = 0

    first_line_flag = []
    for x in [0 .. settings.mapSize - 1]
      first_line_flag[x] = false
    
    for y in [settings.mapSize - 1 .. 1]
      for x in [0 .. settings.mapSize - 1]
        if exploded[x][y]
          first_line_flag[x] = true

          # First step
          for z in [y .. 1]
            @ingredients[x][z].type = @ingredients[x][z-1].type
            exploded[x][z] = exploded[x][z-1]
            displace[x][z] = 1

          @ingredients[x][0].type = Ingredient.randomType()
          exploded[x][0] = false
          displace[x][0] = 1

          # Next steps
          for z in [y .. 1]
            if exploded[x][z]
              for k in [z .. 1]
                @ingredients[x][k].type = @ingredients[x][k-1].type
                exploded[x][k] = exploded[x][k-1]
                displace[x][k] = displace[x][k-1] + 1

              @ingredients[x][0].type = Ingredient.randomType()
              exploded[x][0] = false 
              displace[x][0] = 1

        for z in [y .. 1]
          affected.push([@ingredients[x][z],displace[x][z]])

    for x in [0 .. settings.mapSize-1]
      if exploded[x][0] or first_line_flag[x]
        @ingredients[x][0].type = Ingredient.randomType()
        exploded[x][0] = false

        affected.push([@ingredients[x][0],1])

    @.clearMap()

    affected

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
