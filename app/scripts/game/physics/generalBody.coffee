module.exports = class GeneralBody extends Backbone.Model
  constructor: (def) ->
    @def = def

    s = @def

    @data = s.data

    ids = ["*"]
    if s.id isnt undefined
      ids.push s.id

    if s.el isnt undefined
      el = s.el
      ids.push "#" + el.id if el.id isnt ""
      ids.push "." + className for className in el.classList

    ids.push @data.id if @data.id isnt undefined

    @ids = ids

  getWorkerFn: (name) => return => @call "name", (_.initial arguments), _.last arguments

  getSanitisedDef: ->
    out = _.clone @def
    out.el = undefined
    out.ids = @ids
    out

  attachTo: (world) =>
    @uid = world.attachBody @getSanitisedDef()
    @world = world
    @worker = world.worker
    setTimeout =>
      @destroy -> console.log "destroyed"
    , 1000

  call: (name, args, done) =>
    if done is undefined
      done = args
      args = []
    @worker.send "entityCall",
      uid: @uid
      name: name
      arguments: args
    , done

  destroy: (callback) => @call "destroy", callback
  halt: (callback) => @call "halt", callback
  reset: (callback) => @call "reset", callback
  isAwake: (callback) => @call "isAwake", callback
  position: (p, callback) => @call "position", [p], callback
  positionUncorrected: (callback) => @call "positionUncorrected", callback
  absolutePosition: (callback) => @call "absolutePosition", callback
  angle: (callback) => @call "angle", callback
  angularVelocity: (callback) => @call "angularVelocity", callback
