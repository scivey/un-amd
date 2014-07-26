_ = require 'lodash'
rocambole = require 'rocambole'
m = require './lib/mWrap'
utils = require './lib/utils'
{inspect, log} = utils
esformatter = require 'esformatter'
escodegen = require 'escodegen'
tk = require 'rocambole-token'

formatMsg = (nodes...) ->
    _.chain(nodes)
        .map('type')
        .zip( _.times nodes.length, (-> '->') )
        .flatten(true)
        .initial()
        .value()
        .join('  ')

nParents = (startNode, limit) ->
    out = [startNode]
    count = 0
    current = startNode.parent
    limit = limit or 9999
    while current and (count < limit)
        count++
        out.push current
        current = current.parent
    out.reverse()
    out

findParent = (startNode, pred) ->
    parents = nParents(startNode)
    parents.reverse()
    _.find parents, pred

nextWhen = (x, pred) ->
    current = x
    result = null
    while current
        if pred(current)
            return current
        current = current.next

isUpper = do ->
    reg = /[A-Z]+/gm
    (x) -> reg.test x

isCap = (x) -> isUpper(x.substring(0, 1))


transformer = {
    transformAfter: (ast) ->
        console.warn 'formatAfter....'
        console.warn _.keys(ast)
        _.each ast.tokens, tokenLogger.tokenBefore
}


# esformatter.register(transformer)

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
        y = cleanRoc(x)
        log _.keys(y)
        inspect y


followTokenLinks = (x) ->
    current = x
    out = []
    while current
        out.push current
        current = current.next
    out

getNTokens = (x, n) ->
    out = []
    current = x
    while current and n--
        out.push current
        current = current.next
    out



genFmt = (x) -> esformatter.format x


filterTokes = (startPred, endPred, tokes) ->
    out = []
    started = false
    ended = false
    _.each tokes, (el) ->
        if ended
            return
        unless started
            started = startPred(el)
        if started
            ended = endPred(el)
            unless ended
                out.push el
        return
    out

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

matchingIndices = (pred, elems) ->
    out = []
    _.each elems, (el, i) ->
        if pred(el)
            out.push i
        return
    out



getPreDefineTokens = (tokens) ->
    isDefine = (x) ->
        if x.value is 'define' and x.next.value is '('
            return true

    takeUntil isDefine, tokens

filterDefineTokens = (tokens) ->
    prev = {}
    seenDefine = false
    seenFunc = false
    shouldStart = (x) ->
        if x.value is 'define'
            seenDefine = true
        if seenDefine
            if x.type is 'Keyword' and x.value is 'function'
                seenFunc = true

        if seenFunc and seenDefine and (prev.value is '{')
            return true
        else
            prev = x
        return

    isReturn = (x) ->
        x.type is 'Keyword' and x.value is 'return'

    isDefine = (x) ->
        if x.value is 'define' and x.next.value is '('
            return true

    isClosingBrace = (x) ->
        x.value is '}'

    filtered = dropWhile shouldStart, tokens

    returns = matchingIndices isReturn, filtered
    if returns.length
        filtered = filtered.slice 0, _.last(returns)
    else
        filtered = filtered
        # braces = matchingIndices isClosingBrace, filtered
        # filtered = filtered.slice 0, _.last(braces)

    filtered

filterReturn = (tokens) ->
    isReturn = (x) ->
        x.type is 'Keyword' and x.value is 'return'
    returns = matchingIndices isReturn, tokens
    if returns.length
        tokens = tokens.slice 0, _.last(returns)
    tokens


joinTokens = (tokens) ->
    _.map(tokens, (x) -> if x.raw then x.raw else x.value).join('')


src5 = """
'use strict';
define(['underscore', 'jquery'], function(_, $) {
    var x = Backbone.Model.extend({
        foo: function() {
            this._baz = true;
        }
    });
    // this is a comment
    var y = Backbone.Model.extend({
        bat: function() {
            this._bar = true;
        }
    });

    var AModel = Backbone.Model.extend({
        setBad: function() {
            // is this a good idea??
            this._isGood = false;
        },
        getGoodness: function() {
            return this._isGood;
        }
    });
    return {
        band: band
    };
});
"""


getDefTokens = (tree) ->
    o = _.filter tree.body, (x) ->
        _.has(x, 'expression') and x.expression.type is 'CallExpression'
    o = _.pluck o, 'expression'
    o = _.filter o, (elem) ->
        elem.callee.name is 'define'
    o = o[0]
    defBody = _.last(o.arguments)
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

transformAmd = (src) ->
    {unAmd, AST} = require './index'
    importExport = unAmd.minimal(src)

    requireSrc = importExport.i.toProgram().generate()
    if importExport.o
        exportSrc = importExport.o.toProgram().generate()
    else
        exportSrc = ''

    preDefineSrc = getPreDefineSrc(src)
    bodySrc = getBodySrc(src)

    return [preDefineSrc, requireSrc, bodySrc, exportSrc].join('\n')

doUnAmd = (src) ->
    xformed = transformAmd(src)
    formatted = esformatter.format xformed, {
        indent:
            value: '    '
    }
    return formatted


module.exports = {
    doUnAmd: doUnAmd
}



# t2 = rocambole.parse src5


# tree = new AST(src5)

# better = unAmd(tree)

# t3 = rocambole.parse src5
# tokes = followTokenLinks(t3.startToken)

# output = filterDefineTokens(tokes)
# srcOut = joinTokes(output)
# log srcOut


# b2 = unAmd.minimal(src5)
# b2.i.inspect()




# b2.o.inspect()

# log b2.i.generate()
# foot = b2.o.toProgram().generate()
# head = b2.i.toProgram().generate()

# predef = joinTokes(getPreDefineTokens(tokes))

# out = [predef, head, srcOut, foot].join('\n')

# result = esformatter.format out, {
#     indent:
#         value: '    '
# }
# log result
