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

    # step_count = 0

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

  # solve: (x, y, selected_type) ->
  #   Find exploding fields using recursion
  #   step_count = step_count + 1

  #   if step_count > 10
  #     return

  #   if x < 0 or x > settings.mapSize - 1 or y < 0 or y > settings.mapSize - 1
  #     return

  #   if @ingredients[x][y].type == selected_type
  #     @explode_map[x][y] = true

  #   if ((x-1 >= 0) and (@ingredients[x-1][y].type == selected_type))
  #     left  = true
  #   else
  #     left  = false

  #   if ((y-1 >= 0) and (@ingredients[x][y-1].type == selected_type)) 
  #     down  = true
  #   else
  #     down  = false

  #   if ((x+1 <= settings.mapSize - 1) and (@ingredients[x+1][y].type == selected_type))
  #     right = true
  #   else
  #     right = false

  #   if ((y+1 <= settings.mapSize - 1) and (@ingredients[x][y+1].type == selected_type))
  #     up    = true
  #   else
  #     up    = false
    
  #   if (left or down or right or up) == false
  #     return

  #   @.solve(x-1,y,selected_type,step_count)
  #   @.solve(x,y-1,selected_type,step_count)
  #   @.solve(x+1,y,selected_type,step_count)
  #   @.solve(x,y+1,selected_type,step_count)

  getExplodingIngredients: (selected_position_x, selected_position_y) ->

    result = null

    result = @explode_map if @.hasMatches(selected_position_x, selected_position_y) > 2

    result



  checkAffectedIngredients: (exploded)->

    affected = []
    
    for y in [settings.mapSize - 1 .. 1]
      repeat_flag = true

      while repeat_flag
        for x in [0 .. settings.mapSize - 1]
          if exploded[x][y]
            repeat_flag = true
            for z in [y .. 1]
              @ingredients[x][z].type = @ingredients[x][z-1].type
              exploded[x][z] = exploded[x][z-1]

              affected.push([@ingredients[x][z],1])

            @ingredients[x][0].type = Ingredient.randomType()
            exploded[x][0] = false

            affected.push([@ingredients[x][0],1])

          else
            repeat_flag = false

    for x in [0 .. settings.mapSize-1]
      if exploded[x][0]
        @ingredients[x][0].type = Ingredient.randomType()
        exploded[x][0] = false

        affected.push([@ingredients[x][0],1])

    @.clearMap()

    affected

  # checkAffectedIngredients: (exploded) ->
  #   displacements = []

  #   for x in [0 .. settings.mapSize-1]
  #     for y in [settings.mapSize-1 .. 0]
  #       if exploded[x][y]
  #         # Спуск всех элементов на единицу вниз (делается во временных переменных)
  #         # Дальше проверка на другие "бомбы"
  #         temp_ingr = []
  #         temp_displ = []

  #         # First step
  #         for z in [y .. 1]
  #           temp_ingr[z] = @ingredients[x][z-1]
  #           temp_displ[z] = 1
  #           exploded[x][z] = exploded[x][z-1] #

  #         temp_ingr[0] = @ingredients[x][0]
  #         temp_ingr[0].type = Ingredient.randomType()
  #         temp_displ[0] = 0
  #         exploded[x][0] = false #

  #         # Next steps
  #         for z in [y .. 0]
  #           if exploded[x][z]
  #             for k in [z .. 1]
  #               temp_ingr[k] = temp_ingr[k-1]
  #               temp_displ[k] += 1
  #               exploded[x][k] = exploded[x][k-1] #

  #             temp_ingr[0] = @ingredients[x][0]
  #             temp_ingr[0].type = Ingredient.randomType()
  #             temp_displ[0] = 0
  #             exploded[x][0] = false #

  #         # Margin pushing
  #         for z in [y .. 0]
  #           displacements.push([temp_ingr[z],temp_displ[z]])

  #   @.clearMap()

  #   displacements


  # checkAffectedIngredients: (exploded)->
  #   displacements = []

  #   groups = _.groupBy(exploded, (e)-> e.x )

  #   for column, x in @ingredients
  #     continue unless groups[x]?

  #     displace = 0
  #     displace_cells = []

  #     for y in [column.length - 1 .. 0]
  #       ingredient = column[y]

  #       if exploded.indexOf(ingredient) != -1 # Exploded cell
  #         displace_cells.push(ingredient)

  #       if exploded.indexOf(ingredient) == -1 or y == 0
  #         if displace_cells.length > 0 # There are some cells in stack
  #           for c in displace_cells
  #             @.updateWithDisplacedType(c, displace + displace_cells.length)

  #             displacements.push([c, displace + displace_cells.length])

  #           displace += displace_cells.length
  #           displace_cells = []

  #         if displace > 0
  #           @.updateWithDisplacedType(ingredient, displace)

  #           displacements.push([ingredient, displace])

  #   displacements


  # updateWithDisplacedType: (ingredient, displace)->
  #   ingredient_above = @ingredients[ingredient.x][ingredient.y - displace]

  #   if ingredient_above
  #     ingredient.type = ingredient_above.type
  #   else
  #     ingredient.type = Ingredient.randomType()

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

