m = require './mWrap'
_ = require 'lodash'
utils = require './utils'
traversal = require './traversal'
{log, inspect} = utils
{Tree} = require './tree'
esprima = require 'esprima'
escodegen = require 'escodegen'
jsfmt = require 'jsfmt'

mparse = (src, opts) ->
    opts ?= {}
    m.cljToJs esprima.parse(src, opts)

mgen = (tree, opts) ->
    opts ?= {}
    tree = Tree.valIfTree(tree)
    escodegen.generate m.cljToJs(tree, opts)

nSplit = (n, aList) ->
    _.chain(_.range(0, aList.length))
        .filter( (el) -> (el % n) is 0 )
        .map( (el) -> aList.slice(el, el + n) )
        .value()

AST = (tree) ->
    if utils.isGlobalCtx(this)
        return new AST(tree)
    if _.isString(tree)
        return AST.parse(tree)
    if AST.isAST(tree)
        return tree
    @_isAST = true
    Tree.apply(this, [tree])

AST.isAST = (x) ->
    _.isObject(x) and x._isAST

AST.valIfTree = Tree.valIfTree
AST.isTree = Tree.isTree

_.extend AST.prototype, Tree.prototype

AST.parse = (src) ->
    val = mparse src, {
        comments: true
    }
    return new AST(val)



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
            type = m.get(node, 'type')
            utils.includes('Statement', type) or utils.includes('Variable', type)
    }

    return {
        isType: typePreds
    }


_.extend h, do ->

    xform = {}
    xform.statementsToProg = do ->
        prog = AST m.hashMap("type", "Program", "body", null)
        (stmts) ->
            stmts = AST.valIfTree(stmts)
            prog.assoc 'body', stmts

    xform.stmtToProg = (stmt) ->
        stmts = m.vector AST.valIfTree(stmt)
        xform.statementsToProg stmts

    xform.exprToStmt = do ->
        exprStatement = AST m.hashMap("type", "ExpressionStatement", "expression", null)
        (expr) ->
            expr = AST.valIfTree(expr)
            exprStatement.assoc 'expression', expr

    xform.exprToProg = (x) ->
        x = AST.valIfTree(x)
        xform.stmtToProg xform.exprToStmt(x)

    xform.xToProg = (x) ->
        x = AST.valIfTree(x)
        unless m.isMap(x)
            return xform.statementsToProg(x)
        if h.isType.prog(x)
            return x
        if h.isType.expr(x)
            return xform.stmtToProg(xform.exprToStmt(x))
        if h.isType.stmt(x)
            return xform.stmtToProg(x)
    return {xform: xform}


_.extend h, do ->

    make = {}
    make.lit = do ->
        lit = AST m.hashMap('type', 'Literal', 'value', null, 'raw', null)
        makeNumLit = (x) ->
            lit.assoc('value', x).assoc('raw', "#{x}")
        makeStrLit = (x) ->
            lit.assoc('value', x).assoc('raw', "'#{x}'")
        (x) ->
            if _.isNumber(x)
                makeNumLit(x)
            else
                makeStrLit(x)

    return {make: make}


exportStatement = do ->
    expSrc = """
        module.exports = {
            Thing1: Thing1,
            Thing2: Thing2
        };
    """
    exp = AST(expSrc).get('body').nth(0)
    ->
        exp

swapReturn = (retStmt) ->
    ret = AST(retStmt)
    o = exportStatement()
        .replace(['expression', 'right'], (x) -> ret.get('argument').val())
    o

makeRequireCall = do ->
    baseSrc = "var VARIABLE = require('MODULE');"
    base = Tree(mparse(baseSrc)).get('body').nth(0)
    (varName, modName) ->
        base.traverse (x) ->
            if m.get(x, 'name') is 'VARIABLE'
                return m.assoc(x, 'name', varName)
            else if m.get(x, 'value') is 'MODULE'
                return m.assoc m.assoc(x, 'value', modName), 'raw', "'#{modName}'"

useStrict = do ->
    stmt = h.xform.exprToStmt h.make.lit('use strict')
    ->
        stmt

AST::generate = (opts) ->
    mgen @val(), opts

AST::genFmt = ->
    jsfmt.format @generate()

AST::toProgram = ->
    h.xform.xToProg @val()





unAmd = do ->


    getDefinedDependencies = (defineCall) ->
        defArgs = defineCall.get('arguments')
        if defArgs.count() is 1
            return m.vector()
        scriptDeps = defArgs.get([0, 'elements']).pluck 'value'
        scriptDepNames = defArgs.get([1, 'params']).pluck 'name'
        requires = _.chain( _.zip(scriptDepNames, scriptDeps) )
                        .map( (x) -> makeRequireCall(x[0], x[1]).val() )
                        .value()
        requires = m.into m.vector(), requires
        requires

    getDefineCall = (tree) ->
        tree.find( (x) ->
            if h.isType.callExpr(x)
                if m.getX(x, 'callee.name') is 'define'
                    return true
        ).nth(0)

    getDefineBody = (defineCall) ->
        defArgs = defineCall.get('arguments')
        bodyIndex = defArgs.count() - 1
        defArgs.get [bodyIndex, 'body', 'body']

    minimal = (src) ->
        t = AST(src)
        defineCall = getDefineCall(t)
        dependencies = getDefinedDependencies(defineCall)
        mainBody = getDefineBody(defineCall)
        lastBody = mainBody.get mainBody.lastIndex()
        if lastBody.get('type') isnt 'ReturnStatement'
            exports = null
        else
            exports = swapReturn lastBody
        return {
            i: AST(m.intoArray(dependencies)),
            o: exports
        }

    output = (src) ->
        t = AST(src)
        defineCall = getDefineCall(t)
        dependencies = getDefinedDependencies(defineCall)
        mainBody = getDefineBody(defineCall)
        mainBody = mainBody.replace mainBody.lastIndex(), (retStmt) ->
            swapReturn(retStmt)

        m.each dependencies, (r) ->
            mainBody = mainBody.prepend r

        mainBody = mainBody.prepend(useStrict().val())    
        mainBody.toProgram()

    _.extend output, {
        getDefinedDependencies: getDefinedDependencies
        getDefineCall: getDefineCall
        getDefineBody: getDefineBody
        minimal: minimal
    }
    output



module.exports = {
    unAmd: unAmd
    AST: AST
}

