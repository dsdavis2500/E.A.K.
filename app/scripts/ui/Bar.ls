require! {
  'game/event-loop'
  'lib/channels'
  'settings'
  'user'
}

$overlay = $ '#overlay'
$overlay-views = $ '#overlay-views'

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit
    'click .mute': \toggleMute
    'click .settings-button': \toggleSettings
    'click .logout': \logout

  initialize: ({views}) ->
    @views = views
    @setup-views!

    @$mute-button = @$ '.mute'
    @$settings-button = @$ '.settings-button'
    @$user-bits = @$ '.bar-user-item'
    @$display-name = @$ '.display-name'
    @$login-button = @$ '.login'
    @$logout-button = @$ '.logout'

    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe @start-edit
    channels.page.subscribe ({name, prev}) ~> @activate name, prev
    settings.on 'change:mute', @render, this
    user.on 'change', @render, this

    @render!

  render: ->
    if settings.get 'mute'
      @$mute-button.remove-class 'fa-volume-up' .add-class 'fa-volume-off'
    else
      @$mute-button.remove-class 'fa-volume-off' .add-class 'fa-volume-up'

    if user.get 'available'
      @$user-bits.remove-class 'hidden'
      if user.get 'loggedIn'
        @$display-name.html user.display-name!
        @$login-button.add-class 'hidden'
        @$logout-button.remove-class 'hidden'
      else
        @$login-button.remove-class 'hidden'
        @$logout-button.add-class 'hidden'
    else
      @$user-bits.add-class 'hidden'

  edit: (e) ~>
    e.prevent-default!
    e.stop-propagation!
    @start-edit!
    e.target.blur!

  start-edit: ~>
    unless event-loop.paused then channels.game-commands.publish command: \edit

  toggle-mute: ->
    settings.set 'mute', not settings.get 'mute'

  toggle-settings: ->
    if @active-view then @deactivate! else window.location.hash = '#/app/settings'
  login: -> @activate 'login'
  logout: -> user.logout!

  activate: (view, prev) ->
    if view is \none then return @deactivate!
    if @active-view is view then return
    if @active-view
      @deactivate false, false
    else
      channels.game-commands.publish command: \pause

    if prev
      console.log 'set prev to' prev
      @prev = prev

    @active-view = view
    active = @get-active-view!
      ..$el.add-class 'active'
      ..once 'close', @deactivate, this

    $overlay.add-class 'active'
    $overlay-views.add-class 'active'
    @$settings-button.add-class 'active'
    active.activate! if active.activate?

  deactivate: (overlay = true, resume = true) ->
    old-view = @get-active-view!
    unless old-view then return
    old-view.off 'close', @deactivate, this
    @active-view = null

    to-deactivate = if overlay then [old-view.$el, $overlay] else [old-view.$el]
    to-deactivate.for-each (el) ~>
      el.remove-class 'active' .add-class 'inactive'
      <~ el.one prefixed.animation-end
      el.remove-class 'inactive'
      if el is $overlay then $overlay-views.remove-class 'active'
      if resume
        if @prev then window.location.hash = @prev
        channels.game-commands.publish command: \resume
        resume := false

    if overlay then @$settings-button.remove-class 'active'

  get-active-view: -> @views[@active-view] or null

  setup-views: ->
    for name, view of @views
      view.parent = this
