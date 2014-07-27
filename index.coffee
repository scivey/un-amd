m = require './lib/mWrap'
_ = require 'lodash'
utils = require './lib/utils'
traversal = require './lib/traversal'
{log, inspect} = utils
{Tree} = require './lib/tree'
esprima = require 'esprima'
escodegen = require 'escodegen'
jsfmt = require 'jsfmt'
esformatter = require 'esformatter'

transformAmd = do ->
    {unAmd, AST} = require './lib/ast'
    {getPreDefineSrc, getBodySrc} = require './lib/roc'
    (src) ->
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
    unAmd: doUnAmd
}
