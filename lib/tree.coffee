_ = require 'lodash'
m = require './mWrap'
utils = require './utils'
traversal = require './traversal'
{log} = utils

isSeq = (x) ->
    m.isVector(x) or m.isList(x)

getNth = (target, n) ->
    if m.isMap(target)
        if n is 0
            return target
        else
            return m.vector()
    else if isSeq(target)
        return m.nth(target, n)
    else
        throw new Error("getNth called on non-nth-able thing: #{target} n:#{n}")

processAssocVal = (x) ->
    if Tree.isTree(x)
        return x.val()
    if utils.notSimple(x)
        return m.jsToClj(x)
    return x

errNone = ->
    throw new Error('not implemented')



Tree = (val) ->
    if utils.isGlobalCtx(this)
        return new Tree(val)
    @_isTree = true
    if not val
        val = m.hashMap()
    else if utils.isSimple(val)
        val = m.hashMap()
    else
        val = m.jsToClj(val)
    @_val = val
    this

Tree.isTree = (x) ->
    _.isObject(x) and x._isTree

Tree.valIfTree = (x) ->
    if Tree.isTree(x)
        return x.val()
    x

Tree::val = ->
    @_val

Tree::jsVal = ->
    m.cljToJs @val()

Tree::lift = (x) ->
    return new @constructor(x)

Tree::inspect = ->
    m.inspect @val()
    this

Tree::get = (k) ->
    val = m.getX @val(), k
    if utils.isSimple(val) then val else @lift(val)

Tree::assoc = (k, v) ->
    v = processAssocVal(v)
    result = m.assocX @val(), k, v
    @lift result

Tree::replace = (k, fn) ->
    origVal = Tree.valIfTree @get(k)
    newVal = fn(origVal)
    @assoc k, newVal

Tree::nth = (n) ->
    out = getNth @val(), n
    @lift out    

Tree::first = ->
    @nth 0

Tree::last = ->
    @nth(@count() - 1)

Tree::count = ->
    v = @val()
    if m.isMap(v)
        return 1
    m.count(v)

Tree::lastIndex = ->
    @count() - 1

Tree::slice = (i, j) ->
    errNone()

Tree::remove = (k) ->
    errNone()

Tree::find = (pred) ->
    results = m.vector()
    @traverse (node, parent) ->
        if pred(node, parent)
            results = m.conj results, node
        return
    @lift results

Tree::hasDeep = (pred) ->
    @find(pred).count() isnt 0

Tree::filter = (pred) ->
    errNone()

Tree::map = (mapFn) ->
    m.cljToJs(m.map mapFn, @val())

Tree::equals = (other) ->
    ownVal = @val()
    otherVal = Tree.valIfTree(other)
    m.equals(ownVal, otherVal)

Tree::traverse = (fns) ->
    @lift traversal.traverseObjNodes(@val(), null, fns)

Tree::traverseLimit = (depth, fns) ->
    @lift traversal.traverseObjNodes(@val(), depth, fns)

Tree::children = ->
    @lift traversal.getChildNodes(@val())

Tree::prepend = (val) ->
    v = @val()
    if m.isMap(v)
        v = m.vector v
    result = m.cons val, v
    @lift result

Tree::append = (val) ->
    v = @val()
    if m.isMap(v)
        v.m.vector(v)
    result = m.conj v, val
    @lift result

module.exports = {
    Tree: Tree
}

