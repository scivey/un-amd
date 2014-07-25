m = require './lib/mWrap'
_ = require 'lodash'
utils = require './lib/utils'

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

Tree = (val) ->
    @_isTree = true
    @_val = m.jsToClj(val)
    this

Tree.isTree = (x) ->
    _.isObject(x) and x._isTree

processAssocVal = (x) ->
    if Tree.isTree(x)
        return x.val()
    if notSimple(x)
        return m.jsToClj(x)
    return x


Tree::val = ->
    @_val


Tree::lift = (x) ->
    return new Tree(x)


Tree::inspect = ->
    m.inspect @val()
    this

Tree::assoc = (k, v) ->
    v = processAssocVal(v)
    val = m.assocX @val(), k, v
    @lift val

Tree::get = (k, v) ->
    val = m.getX @val(), k, v
    if isSimple(val) then val else @lift(val)


ctx =
    a:
        x: 10
        y: 5
    b: 17
    c:
        q:
            r: 10
            s: 7
        g: 3
    d:
        j: 3
        f: 'e'


# utils.inspect(ctx)

x = new Tree(ctx)
x.inspect()
y.inspect()

