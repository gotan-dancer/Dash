window.XYMap = class

  constructor: ->
    @xy_map = []

    for x in [0 .. settings.mapSize - 1]
      @xy_map[x] = []

      for y in [0 .. settings.mapSize - 1]
        @xy_map[x][y] = false

  isTypeEqual: (x, y) ->
    @xy_map[x][y] = true

  clearMap: ->
    for x in [0 .. settings.mapSize - 1]
      for y in [0 .. settings.mapSize - 1]
        @xy_map[x][y] = false
