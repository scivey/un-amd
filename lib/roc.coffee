_ = require 'lodash'
rocambole = require 'rocambole'
m = require './mWrap'
utils = require './utils'
{inspect, log} = utils
esformatter = require 'esformatter'
escodegen = require 'escodegen'
tk = require 'rocambole-token'

getType = (x) ->
    if _.isObject(x)
        if _.has(x, 'type')
            return x.type
    return typeof x

getTypeOrLit = (val) ->
    if _.isNumber(val) or _.isNumber(val)
        return val
    getType(val)

rocspect = do ->
    cleanRocNode = (x) ->
        out = {}
        _.each x, (val, key) ->
            if _.isArray(val)
                out[key] = _.map(val, getTypeOrLit)
            else if _.isObject(val)
                out[key] = val.type
            else
                out[key] = val
        out
    cleanRoc = (x) ->
        if _.isArray(x)
            _.map x, cleanRocNode
        else
            cleanRocNode(x)
    (x) ->
        inspect cleanRoc(x)

followTokenLinks = (x) ->
    current = x
    out = []
    while current
        out.push current
        current = current.next
    out

genFmt = (x) -> esformatter.format x

takeWhile = (pred, elems) ->
    out = []
    keepGoing = true
    _.each elems, (el) ->
        if keepGoing
            keepGoing = pred(el)
            if keepGoing
                out.push el
        return
    out

takeUntil = (endPred, elems) ->
    pred = (x) -> not endPred(x)
    takeWhile pred, elems

dropWhile = (startPred, elems) ->
    out = []
    started = false
    _.each elems, (el) ->
        unless started
            started = startPred(el)
        if started
            out.push el
        return
    out

getPreDefineTokens = (tokens) ->
    isDefine = (x) ->
        if x.value is 'define' and x.next.value is '('
            return true

    takeUntil isDefine, tokens

joinTokens = (tokens) ->
    _.map(tokens, (x) -> if x.raw then x.raw else x.value).join('')

getDefTokens = (tree) ->
    matching = _.chain(tree.body)
        .filter( (x) -> _.has(x, 'expression') and x.expression.type is 'CallExpression' )
        .pluck('expression')
        .filter( (x) -> x.callee.name is 'define' )
        .value()
    matching = matching[0]
    defBody = _.last(matching.arguments)
    body = defBody.body
    tokenStart = body.startToken.next
    lastToken = body.endToken

    lastStatement = _.last(body.body)
    if lastStatement.type is 'ReturnStatement'
        lastToken = lastStatement.startToken

    lastToken.prev.next = undefined
    followTokenLinks(tokenStart)

getPreDefineSrc = (src) ->
    rocTree = rocambole.parse src
    preDefineCallTokens = getPreDefineTokens followTokenLinks(rocTree.startToken)
    joinTokens preDefineCallTokens

getBodySrc = (src) ->
    rocTree = rocambole.parse src
    defBodyTokens = getDefTokens rocTree
    joinTokens defBodyTokens

module.exports = {
    getPreDefineSrc: getPreDefineSrc
    getBodySrc: getBodySrc
}

