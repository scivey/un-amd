m = require './lib/mWrap'
_ = require 'lodash'
utils = require './lib/utils'
traversal = require './lib/traversal'
{log, inspect} = utils
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

nSplit = (n, aList) ->
    _.chain(_.range(0, aList.length))
        .filter( (el) -> (el % n) is 0 )
        .map( (el) -> aList.slice(el, el + n) )
        .value()

h = do ->
    types = [
        ['exprStmt'],       'ExpressionStatement'
        ['emptyStmt'],      'EmptyStatement'
        ['blockStmt'],      'BlockStatement'
        ['retStmt'],        'ReturnStatement'
        ['ifStmt'],         'IfStatement'
        ['declaration'],    'VariableDeclaration'
        ['declarator'],     'VariableDeclarator'
        ['funcDecl'],       'FunctionDeclaration'
        ['funcExpr'],       'FunctionExpression'
        ['callExpr'],       'CallExpression'
        ['arrayExpr'],      'ArrayExpression'
        ['objExpr'],        'ObjectExpression'
        ['binExpr'],        'BinaryExpression'
        ['unExpr'],         'UnaryExpression'
        ['assnExpr'],       'AssignmentExpression'
        ['memExpr'],        'MemberExpression'
        ['prog'],           'Program'
        ['prop'],           'Property'
        ['lit'],            'Literal'
        ['id'],             'Identifier'
    ]

    testPred = _.curry( (type, node) -> m.get(node, 'type') is type )

    typePreds = {}
    _.each nSplit(2, types), (pair) ->
        aliases = pair[0]
        typeName = pair[1]
        aPred = testPred(typeName)
        _.each aliases, (oneAlias) ->
            typePreds[oneAlias] = aPred

    _.extend typePreds, {
        expr: (node) ->
            type = m.get(node, 'type')
            utils.includes('Expression', type) and type isnt 'ExpressionStatement'
        stmt: (node) ->
            utils.includes('Statement', m.get(node, 'type'))
    }

    return {
        isType: typePreds
    }


src = """
var x = 10;
var y = 19 / 2;
var z = x + y;
var plonk = function(a, b, c) {
    return a + b + c;
};
var qq = plonk(x, y, z);
var sea = {
    nano: 'foo',
    doThing: function(x) {
        console.log(x);
    }
};
sea.zap.why = 'plew!';
function mult(m1, m2) {
    return m1 * m2;
};
function isMult(aa, bb) {
    if (mult(aa, bb) > 50) {
        return true;
    } else {
        return false;
    }
};
"""

src2 = """
define(['underscore', 'jquery', 'backbone'], function(_, $, Backbone) {
    var AModel = Backbone.Model.extend({
        initialize: function(props) {
            this.listenToSomething(props.x);
        }
    });

    // this is a comment....
    var AView = Backbone.View.extend({
        initialize: function() {
            console.warn('initialized');
        }
    });

    return {
        AModel: AModel,
        AView: AView
    };
});
"""



# tt = new Tree(mparse(src))
# # tt.inspect()
# x = tt.get 'body'
# # tt.get('body').inspect().nth(1).inspect()


# yy = tt.traverse (x) ->
#     if h.isType.id(x)
#         if m.get(x, 'name') is 'y'
#             return m.assoc(x, 'name', 'theta')


# y2 = tt.find (x, y) ->
#     if h.isType.funcExpr(x)
#         t2 = new Tree(x)
#         t2.hasDeep (el) -> m.get(el, 'name') is 'console'


# y2.inspect()
# # yy.find( (x) -> h.isType.id(x) ).inspect()
# yy.inspect()
# tt.inspect()

exportStatement = do ->
    expSrc = """
        module.exports = {
            Thing1: Thing1,
            Thing2: Thing2
        };
    """
    exp = Tree(mparse(expSrc))
    exp = exp.get('body').nth(0)
    ->
        exp

t = Tree(mparse(src2))
t.inspect()

swapReturn = (retStmt) ->
    ret = Tree(retStmt)
    o = exportStatement()
        .replace(['expression', 'right'], (x) -> ret.get('argument').val())
    o.inspect()
    o

makeRequireCall = do ->
    baseSrc = "var VARIABLE = require('MODULE');"
    base = Tree(mparse(baseSrc)).get('body').nth(0)
    (varName, modName) ->
        base.traverse (x) ->
            if m.get(x, 'name') is 'VARIABLE'
                return m.assoc(x, 'name', varName)
            else if m.get(x, 'value') is 'MODULE'
                mapped = m.assoc(x, 'value', modName)
                return m.assoc(mapped, 'raw', "'#{modName}'")

t2 = t.traverse (x) ->
    if h.isType.retStmt(x)
        return swapReturn(x).val()
        # return exportStatement().val()

t3 = t.find( (x) -> 
    if h.isType.callExpr(x)
        if m.getX(x, 'callee.name') is 'define'
            return true
    ).nth(0)


scriptDeps = t3.get(['arguments', 0, 'elements']).map (x) -> m.get(x, 'value')
scriptDepNames = t3.get(['arguments', 1, 'params']).map (x) -> m.get(x, 'name')
requires = _.map _.zip(scriptDepNames, scriptDeps), (x) -> makeRequireCall(x[0], x[1])
requires = _.map requires, (x) -> x.val()
requires = m.into m.vector(), requires

reqs = Tree(requires)
reqs.inspect()

scriptBody = t3.get ['arguments', 1, 'body', 'body']
scriptBody.inspect()
zz = scriptBody.replace (scriptBody.count() - 1), -> "ZAP"
zz.inspect()

# scriptBody.inspect()
