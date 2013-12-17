class SoundManager
  ready: false
  slider: null

  sound_volume: window.sound_volume || 50
  music_volume: window.music_volume || 50

  constructor: ->
    @manager = window.soundManager

    @manager.url = '/assets'
    @manager.useHTML5Audio = true
    @manager.preferFlash = false
    @manager.flashVersion = 9
    @manager.useFlashBlock = false

    @sounds = {}

    @manager.onready ()=>
      @sounds = {
        swap: @manager.createSound(
          id: 'swap',
          url: '$assetPath(swap.mp3)'
        ).load()

        explode: @manager.createSound(
          id: 'explode',
          url: '$assetPath(explode.mp3)'
        ).load()

        potion: @manager.createSound(
          id: 'potion',
          url: '$assetPath(potion.mp3)'
        ).load()
      }

      @ready = true

      @.setSoundVolume(@sound_volume)

  fadeInMusic: =>
    current_volume = @manager.getSoundById('music').volume

    return if current_volume >= @music_volume

    @manager.setVolume('music', current_volume + 1)

    setTimeout(@.fadeInMusic, 100)

  setSoundVolume: (volume)->
    @sound_volume = Math.min(100, Math.max(0, volume))

    for key, value of @sounds
      @manager.setVolume(key, @sound_volume) unless key == 'music'

  setMusicVolume: (volume)->
    @music_volume = Math.min(100, Math.max(0, volume))

    @manager.setVolume('music', @music_volume)

  updateVolume: (sound_volume, music_volume)->
    @.setSoundVolume(sound_volume)
    @.setMusicVolume(music_volume)

    $.post('/games/update_volume', sound: @sound_volume, music: @music_volume)

  playSound: (key)->
    @sounds[key]?.play()

  loopSound: (key)->
    @sounds[key]?.play(loops: 9999, multiShot: false)

  startMusic: ->
    @.loopSound('music')

window.sounds = new SoundManager
