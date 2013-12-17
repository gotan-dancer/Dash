window.Potion = class
  constructor: (@size)->
    @ingredients = []

    for c in [1 .. @size]
      @ingredients.push [Ingredient.randomType(), false]

  checkCollectedIngredients: (exploded)->
    result = []

    exploded = _.groupBy(exploded, (e)-> e.type)

    for type, ingredients of exploded
      for i in [0 .. Math.floor(ingredients.length / 3 - 1)]
        ingredient = ingredients[i * 3]

        missing = @.getMissing(ingredient.type)

        continue unless missing

        missing[1] = true

        result.push(ingredient)

    result

  getMissing: (type)->
    for record in @ingredients
      return record if record[0] == type and not record[1]

    null

  isComplete: ->
    for [type, collected] in @ingredients
      return false unless collected

    true