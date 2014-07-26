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

t = new Tree(src2)
t.inspect()
