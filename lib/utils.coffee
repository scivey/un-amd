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

helpers = h = {
    negate: _.curry( (fn, x) -> not fn(x) )
    
    isSimple: (x) -> return true unless _.isObject(x)
    
    notSimple: h.negate(h.isSimple)
    
    parse10: (x) -> parseInt(x)

    includes: _.curry( (y, x) -> x.indexOf(y) isnt -1 )

    isIntStr: do ->
        numeric = /^[0-9]+$/igm
        (x) -> numeric.test(x)
    
    notIntStr: h.negate(h.isIntStr)
    
    maybeIntStr: (x) ->
        if _.isNumber(x) then return x
        if h.notIntStr(x) then return x
        return h.parse10(x)

    keyString: (x) ->
        return x unless h.includes('.', x)
        parts = _.map x.split('.'), (v) ->
            h.maybeIntStr(v)
        parts

}


module.exports = _.extend helpers, {
    kamelKey: kamelKey
    inspect: inspect
}
