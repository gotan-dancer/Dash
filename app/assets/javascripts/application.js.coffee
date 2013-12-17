#= require jquery
#= require jquery_ujs

#= require underscore
#= require visibility
#= require pixi
#= require tweenjs

#= require spine

#= require i18n
#= require i18n/translations

#= require soundmanager2
#= require sounds

#= require_tree ./lib
#= require_tree ./helpers
#= require_tree ./controllers
#= require_tree ./models
#= require_tree ./views

#= require preloadjs

#= require preloader

#= require_self

window.settings =
  mapSize: 9
  timeLimit: 60 # You have only one minute!
  timeBonus: 15
  scores:
    3: 2
    4: 5
    5: 10
    potion: 15

window.Application = class
  start: ->
    $('#preloader').hide()
    $('#game_screen').css(visibility: 'visible')

    @level = new LevelController()
    @level.show()

    TutorialDialogController.show(@level)

$ =>
  window.preloader = new Preloader(=>
    window.application = new Application()
    window.application.start()

    _gaq?.push(['_trackTiming', 'Game Load', 'Start', Date.now() - load_started_at, null, 100])
  )
