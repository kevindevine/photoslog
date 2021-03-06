View = require('view')
SVGView = require('svgView')
imageLoader = require('imageLoader')
roundf = require('tools').roundf

class ImageView extends View
  className: 'imageView'

  constructor: ->
    super

    @disabled = false
    @loaded = false
    @loadObject = null
    @bindEvents()

    if @options.loadingIndicator
      @cover = new View(className: 'cover')
      @cover.css(visibility: 'hidden')
      @addSubview(@cover)
      @hiddenCover = true

  bindEvents: =>
    @el.addEventListener('click', @onClick)

  load: (done) =>
    if @options.queue?
      @options.queue.addJob(@_load)
    else
      @_load(done)

  setDisabled: (bool) =>
    return if bool == @disabled
    @disabled = bool
    if bool
      @el.style.backgroundImage = "none"
    else if @loaded
      @apply()

  showCover: =>
    return unless @cover?
    if @hiddenCover
      @cover.css(visibility: 'visible')
      @hiddenCover = false

  setLoadingProgress: (progress) =>
    return unless @options.loadingIndicator

    if progress < 100
      frame = @loadingIndicatorFrame(progress)
      @el.style.webkitClipPath = @insetFromFrame(frame)
      @showCover()

  loadingIndicatorFrame: (progress) =>
    frame = {}
    frame.width = progress / 100 * @width() * 0.3
    frame.height = 2
    frame.x = Math.round((@width() - frame.width) / 2)
    frame.y = Math.round((@height() - frame.height) / 2)
    frame

  insetFromFrame: (frame) =>
    "inset(#{roundf(frame.y, 2)}px #{roundf(frame.x, 2)}px #{roundf(frame.y, 2)}px #{roundf(frame.x, 2)}px)"

  show: (done) =>
    return unless @options.loadingIndicator

    frame = @loadingIndicatorFrame(100)

    if @visibleBounds()?
      @el.style.webkitClipPath = @insetFromFrame(frame)
      @showCover()

      cover = @cover
      frame.opacity = 1
      dynamics(frame, {
        x: 0,
        y: 0
        width: @width(),
        height: @height(),
        opacity: 0
      }, {
        type: dynamics.EaseInOut
        duration: 1000,
        friction: 200,
        change: =>
          inset = "inset(#{roundf(frame.y, 2)}px #{roundf(frame.x, 2)}px #{roundf(frame.y, 2)}px #{roundf(frame.x, 2)}px)"
          @el.style.webkitClipPath = inset
          cover.css(opacity: frame.opacity)
        complete: =>
          cover.removeFromSuperview()
          done()
      })
    else
      @cover.removeFromSuperview()
      @el.style.webkitClipPath = 'none'
      done()
    @cover = null

  _load: (done) =>
    @loadObject = imageLoader.get(@options.imagePath)
    @loadObject.on('progress', =>
      @setLoadingProgress(@loadObject.progress)
    )
    @loadObject.on('load', =>
      @onLoad()
      done()
    )

    if @loadObject.url
      @onLoad()
      done()

  apply: =>
    @el.style.backgroundImage = "url(#{@loadObject.url})"

  onClick: =>
    @trigger('click', @)

  onLoad: =>
    @setLoadingProgress(100)
    @loaded = true
    @apply()
    @show =>
      @el.classList.add('loaded')

module.exports = ImageView
