window.IngredientMap = class
  constructor: ->
    @ingredients = []

    for x in [0 .. settings.mapSize - 1]
      @ingredients[x] = []

      for y in [0 .. settings.mapSize - 1]
        @ingredients[x][y] = new Ingredient(x,y, Ingredient.randomType())

  get: (x, y)->
    @ingredients[x][y]

  isMatch: (ingredient1) -> 
    @.isPurposeMatch(ingredient1)

  isCoordinateMatch: (ingredient1, ingredient2)->
    (ingredient1.x - 1 <= ingredient2.x <= ingredient1.x + 1 and ingredient1.y == ingredient2.y) or
    (ingredient1.y - 1 <= ingredient2.y <= ingredient1.y + 1 and ingredient1.x == ingredient2.x)

  isTypeMatch: (ingredient1, ingredient2)->
    ingredient1.type != ingredient2.type

  isPurposeMatch: (ingredient1) -> 
    matches1 = @.hasMatches(ingredient1)

    matches1

  hasMatches: (ingredient)->
    for match in @.matchesOf(ingredient)
      return true if match

    false

  matchesOf: (ingredient)->
    [
      @ingredients[ingredient.x - 2]?[ingredient.y]?.type == @ingredients[ingredient.x - 1]?[ingredient.y]?.type == ingredient.type
      @ingredients[ingredient.x - 1]?[ingredient.y]?.type == @ingredients[ingredient.x + 1]?[ingredient.y]?.type == ingredient.type
      @ingredients[ingredient.x + 1]?[ingredient.y]?.type == @ingredients[ingredient.x + 2]?[ingredient.y]?.type == ingredient.type

      @ingredients[ingredient.x]?[ingredient.y - 2]?.type == @ingredients[ingredient.x]?[ingredient.y - 1]?.type == ingredient.type
      @ingredients[ingredient.x]?[ingredient.y - 1]?.type == @ingredients[ingredient.x]?[ingredient.y + 1]?.type == ingredient.type
      @ingredients[ingredient.x]?[ingredient.y + 1]?.type == @ingredients[ingredient.x]?[ingredient.y + 2]?.type == ingredient.type
    ]

  getExplodingIngredients: ->
    result = []

    for column in @ingredients
      for ingredient in column
        result.push(ingredient) if @.hasMatches(ingredient)

    result

  checkAffectedIngredients: (exploded)->
    displacements = []

    groups = _.groupBy(exploded, (e)-> e.x )

    for column, x in @ingredients
      continue unless groups[x]?

      displace = 0
      displace_cells = []

      for y in [column.length - 1 .. 0]
        ingredient = column[y]

        if exploded.indexOf(ingredient) != -1 # Exploded cell
          displace_cells.push(ingredient)

        if exploded.indexOf(ingredient) == -1 or y == 0
          if displace_cells.length > 0 # There are some cells in stack
            for c in displace_cells
              @.updateWithDisplacedType(c, displace + displace_cells.length)

              displacements.push([c, displace + displace_cells.length])

            displace += displace_cells.length
            displace_cells = []

          if displace > 0
            @.updateWithDisplacedType(ingredient, displace)

            displacements.push([ingredient, displace])

    displacements


  updateWithDisplacedType: (ingredient, displace)->
    ingredient_above = @ingredients[ingredient.x][ingredient.y - displace]

    if ingredient_above
      ingredient.type = ingredient_above.type
    else
      ingredient.type = Ingredient.randomType()
      ingredient.type = Ingredient.randomType() while @.hasMatches(ingredient)

  calculateExplodingScore: ->
    result = []

    for x in [0 .. settings.mapSize - 1]
      horizontal = 0

      for y in [0 .. settings.mapSize - 1]
        if @ingredients[x][y].exploding
          horizontal += 1
        else if horizontal >= 3
          result.push(horizontal)
          horizontal = 0

      result.push(horizontal) if horizontal >= 3

    for y in [0 .. settings.mapSize - 1]
      vertical = 0

      for x in [0 .. settings.mapSize - 1]
        if @ingredients[x][y].exploding
          vertical += 1
        else if vertical >= 3
          result.push(vertical)
          vertical = 0

      result.push(vertical) if vertical >= 3

    sum = 0

    for count in result
      sum += settings.scores[count]

    sum