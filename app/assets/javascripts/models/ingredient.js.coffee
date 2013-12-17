window.Ingredient = class
  @types: ['blue', 'green', 'purple', 'orange', 'red', 'yellow']

  @randomType: ->
    @.types[_.random(@.types.length - 1)]

  constructor: (@x, @y, @type)->
    @id = _.random(0, 1000000000)

    @selected = false
    @exploding = false

  toggleSelection: ->
    @selected = not @selected
