m = require './lib/mWrap'
_ = require 'lodash'
utils = require './lib/utils'
traversal = require './lib/traversal'
{log} = utils
{Tree} = require './lib/tree'
esprima = require 'esprima'
escodegen = require 'escodegen'

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
    e2: [37, {zap: 2}]
    f2: [9, 3, 2]


mparse = (src) ->
    m.cljToJs(esprima.parse(src))

mgen = (tree) ->
    escodegen.generate m.jsToClj(tree)

src = """
var x = 10;
var y = 19 / 2;
var z = x + y;
"""

tt = new Tree(mparse(src))
tt.inspect()
x = tt.get 'body'
tt.get('body').inspect().nth(1).inspect()




yy = tt.traverse (x) ->
    if m.get(x, 'type') is 'Identifier'
        if m.get(x, 'name') is 'y'
            return m.assoc(x, 'name', 'theta')

yy.inspect()


