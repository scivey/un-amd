_ = require 'lodash'
_str = require 'underscore.string'

kamelKey = (k) ->
    if k.indexOf('_') is 0
        '_' + kamelKey(k.substring(1))
    else
        _str.camelize(k)

inspect = do ->
    util = require 'util'
    opts =
        depth: null
        colors: true
    (ref) ->
        console.log util.inspect(ref, opts)

negate = (fn, x) ->
    result = fn(x)
    if result then false else true

h = {
    negate: _.curry( negate )
    isSimple: (x) -> return true unless _.isObject(x)
    parse10: (x) -> parseInt(x)
    includes: _.curry( (y, x) -> x.indexOf(y) isnt -1 )
}

h.isIntStr = do ->
    numeric = /^[0-9]+$/igm
    (x) -> 
        numeric.test(x)

h.flatten1 = (x) ->
    shallow = true
    _.flatten x, shallow

_.extend h, {
    notIntStr: h.negate(h.isIntStr)
    notSimple: h.negate(h.isSimple)
}

h.extend = (parts...) ->
    result = {}
    args = h.flatten1 [result, parts]
    _.extend.apply _, args
    result

h.maybeIntStr = (x) ->
    if _.isNumber(x) then return x
    if h.notIntStr(x) then return x
    return h.parse10(x)



h.keyString = (x) ->
    return x unless h.includes('.', x)
    parts = _.map x.split('.'), (v) ->
        h.maybeIntStr(v)
    parts


h.isGlobalCtx = do ->
    _ctx = this
    (test) ->
        test is _ctx

output = h.extend h, {
    kamelKey: kamelKey
    inspect: inspect
    log: _.bind(console.log, console)
}

module.exports = output
