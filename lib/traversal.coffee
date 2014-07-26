m = require './mWrap'
_ = require 'lodash'
utils = require './utils'

eachVal = (aMap, fn) ->
    m.each aMap, (kv) ->
        key = m.nth kv, 0
        val = mnth kv, 1
        fn()

isSeq = (x) ->
    m.isVector(x) or m.isList(x)

mapper = (x, fn) ->
    m.map fn, x


mValMap = (aMap, fn) ->
    result = aMap
    m.each aMap, (kv) ->
        key = m.nth kv, 0
        val = m.nth kv, 1
        newVal = fn(val)
        result = m.assoc(result, k, newVal)
    result

eachVal = (aMap, fn) ->
    m.each aMap, (kv) ->
        val = m.nth kv, 1
        fn(val)


t = {}

t.mapType = (aMap, fns, parent, maxDepth, currentDepth) ->
    parent = parent or aMap
    result = aMap
    m.each aMap, (kv) ->
        key = m.nth kv, 0
        val = m.nth kv, 1
        newVal = t.xType(val, fns, parent, maxDepth, currentDepth)
        unless _.isUndefined(newVal)
            result = m.assoc result, key, newVal
    result


t.listType = (aList, fns, parent, maxDepth, currentDepth) ->
    parent = parent or aList
    result = mapper aList, (val) ->
        newVal = t.xType(val, fns, parent, maxDepth, currentDepth)
        if _.isUndefined(newVal)
            newVal = val
        newVal
    result


t.visitOneFn = (val, fn, parent) ->
    result = fn(val, parent)
    if _.isUndefined(result)
        result = val
    return result

t.xType = (val, fns, parent, maxDepth, currentDepth) ->
    if maxDepth
        currentDepth = currentDepth or 0
        if currentDepth >= maxDepth
            return val

    currentDepth += 1

    if fns.enter
        val = t.visitOneFn val, fns.enter, parent

    if m.isMap(val)
        val = t.mapType(val, fns, val, maxDepth, currentDepth)
    else if isSeq(val)
        val = t.listType(val, fns, val, maxDepth, currentDepth)

    if fns.exit
        val = t.visitOneFn val, fns.exit, parent

    val

ensureFnFormat = (fns) ->
    if _.isFunction(fns)
        fns = {
            enter: fns
        }
    return fns

traverseAllTypes = (tree, maxDepth, fns) ->
    fns = ensureFnFormat(fns)
    t.xType tree, fns, null, maxDepth


makeFilteredVisitor = do ->
    makeFiltered = (pred, fn, x, y) ->
        if pred(x, y)
            return fn(x, y)

    _.curry(makeFiltered)


traverseFiltered = (tree, maxDepth, pred, fns) ->
    fns = _.clone(ensureFnFormat(fns))
    _.each fns, (oneFn, key) ->
        fns[key] = makeFilteredVisitor(pred, oneFn)
    return traverseAllTypes(tree, maxDepth, fns)


mFilt = (aList, pred) ->
    results = m.vector()
    m.each aList, (el) ->
        if pred(el)
            results = m.conj results, el
    results

getChildNodes = (aNode) ->
    results = m.vector()
    eachVal aNode, (val) ->
        if m.isMap(val)
            results = m.conj results, val
        else if isSeq(val)
            mas = mFilt val, (x) ->
                m.isMap(x)
            console.log('mas', mas)
            results = m.into results, mas
    results


isNode = (x) ->
    _.isObject(x) and m.isMap(x)

traverseObjNodes = (tree, maxDepth, fns) ->
    traverseFiltered tree, maxDepth, isNode, fns


module.exports = {
    traverseAllTypes: traverseAllTypes
    traverseFiltered: traverseFiltered
    traverseObjNodes: traverseObjNodes
    getChildNodes: getChildNodes
}