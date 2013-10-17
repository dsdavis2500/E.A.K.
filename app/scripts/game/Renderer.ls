require! {
  'game/dom/Mapper'
  'game/lang/CSS'
  'game/mediator'
}

transform = Modernizr.prefixed \transform

module.exports = class Renderer extends Backbone.View
  tag-name: \div
  class-name: 'level no-html hidden'

  id: -> "levelrenderer-#{Date.now!}"

  initialize: (options) ->
    @{root} = options
    @$el.append-to @root

    style = $ '<style></style>'
    style.append-to document.head
    @$style = style

    @set-HTML-CSS options.html, options.css

    @listen-to mediator, \resize @resize

    @resize!
    @render!
    @mapper = new Mapper @el

    @listen-to mediator, \playermove @move

  set-HTML-CSS: (html, css) ~>
    @current-HTML = html
    @current-CSS = css

    @$el.html html

    css = new CSS css
    css.scope \# + @el.id
    css.to-string! |> @$style.text

  create-map: ~>
    @$el.css left: 0, top: 0, margin-left: 0, margin-top: 0
    @mapper.build!
    @map = @mapper.map
    @resize!
    @map

  render: ~>
    # Not a brilliant name, considering it only makes already-rendered stuff
    # visible
    @$el.remove-class \hidden

  remove: (done = ->) ~>
    @$el.add-class \hidden
    $ document.body .remove-class \playing
    <~ set-timeout _, 1000
    @$style.remove!
    super
    done!

  resize: ~>
    el-width = @width = @$el.width!
    el-height = @height = @$el.height!
    win-width = @$window.width!
    win-height = @$window.height!

    if @editor then win-width = win-width / 2

    scrolling = x: no, y: no

    unless @last-position? => @last-position = x: 0, y: 0

    if win-width < el-width
      scrolling.x = win-width
      @$el.css left: 0, margin-left: ''
    else
      @$el.css left: '50%', margin-left: -el-width / 2

    if win-height < el-height
      scrolling.y = win-height
      @$el.css top: 0, margin-top: 0
    else
      @$el.css top: '50%', margin-top: -el-height / 2

    @scrolling = scrolling

  set-width: (width) ~>
    @$el.width width
    @resize!

  set-height: (height) ~>
    @$el.height height
    @resize!

  const pad = 30
  const damping = 10

  move: (position) ~>
    l = @last-position.{x, y}

    t =
      x: l.x + (position.x - l.x) / damping
      y: l.y + (position.y - l.y) / damping

    @last-position = t.{x, y}

    @move-direct t.{x, y}

  move-direct: (position, scroll = false) ~>
    s = @scrolling
    w = @width
    h = @height

    t =
      x: if s.x then ((w + 2*pad) - s.x) * (position.x / w) - pad else 0
      y: if s.y then ((h + 2*pad) - s.y) * (position.y / h) - pad else 0

    @el.style[transform] = if t.x is 0 and t.y is 0 then '' else "translate3d(#{-t.x}px, #{-t.y}px, 0)"

  $window: $ window