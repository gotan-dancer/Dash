window.Timer = class
  constructor: (countdown)->
    @.start(countdown)

  start: (countdown)->
    @finish_at = Date.now() + countdown * 1000

  currentValue: ->
    return @pause_at if @pause_at?

    value = Math.ceil((@finish_at - Date.now()) / 1000)

    if value < 0 then 0 else value

  increment: (value)->
    if value + @.currentValue() > settings.timeLimit
      @finish_at = Date.now() + settings.timeLimit * 1000
    else
      @finish_at += value * 1000

  pause: ->
    @pause_at = @.currentValue()

  resume: ->
    @.start(@pause_at)

    delete @pause_at