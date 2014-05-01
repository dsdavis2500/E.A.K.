require! {
  'game/mediator'
  'logger'
}

actions = {
  kill: (player) ->
    player.fall-to-death!

  spike: (player) -> actions.kill player
}

# Hyperlinks
mediator.on 'begin-contact:HYPERLINK:ENTITY_PLAYER' (contact) ->
  if contact.b.deactivated then return
  speed = contact.b.last-v.y
  if 3.5px < speed < 10px then window.location.href = contact.a.el.href

# Portals
mediator.on 'begin-contact:PORTAL:ENTITY_PLAYER' (contact) ->
  <- set-timeout _, 250
  if contact.b.deactivated then return

  if contact.b.last-fall-dist > 200px then return

  contact.b
    ..frozen = true
    ..handle-input = false
    ..classes-disabled = true

  contact.b.el.class-list.add 'portal-out'
  contact.a.el.class-list.add 'portal-out'

  logger.log 'portal', player: contact.b.{p, v}

  <- set-timeout _, 750
  window.location.href = contact.a.el.href

# Falling to death, actions:
mediator.on 'begin-contact:ENTITY_PLAYER:*' (contact) ->
  if contact.a.deactivated then return

  # First, check for and trigger actions
  if contact.b.data?.action?
    action = contact.b.data.action
    if actions[action]?
      logger.log 'action', {action}
      actions[action] contact.a, contact.b

  if contact.a.last-fall-dist > 300px and not contact.b.data?.sensor?
    mediator.trigger 'fall-to-death'

# Kitten finding
mediator.on 'begin-contact:ENTITY_TARGET:ENTITY_PLAYER' (contact) ->
  if contact.b.deactivated then return
  target = contact.a

  target.destroy!

  unless target.destroyed
    logger.log 'kitten', player: contact.b.{v, p}
    mediator.trigger 'kittenfound'

  target.destroyed = true

  $el = $ target.el

  $el.one prefixed.animation-end, -> $el.remove!

  $el.add-class 'found'

