_ = require 'lodash'
utils = require './utils'

m = do ->
    mori = require 'mori'
    out = {}
    _.each mori, (v, k) ->
        key = utils.kamelKey(k)
        out[key] = (args...) ->
            mori[k].apply(mori, args)
    out


jsFn = _.curry( (fn, x) -> fn(m.cljToJs(x)) )

helpers = h = {
    inspect: jsFn(utils.inspect)
    assocX: (target, k, v) ->
        if _.isArray(k)
            return m.assocIn(target, k, v)
        return m.assoc(target, k, v)
    getX: (target, k) ->
        if _.isString(k)
            k = utils.keyString(k)
        if _.isArray(k)
            return m.getIn(target, k)
        return m.get(target, k)
}

_.extend m, helpers

module.exports = m
