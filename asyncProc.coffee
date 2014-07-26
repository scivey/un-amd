fs = require 'fs'
path = require 'path'
_ = require 'lodash'
async = require 'async'
{log, inspect} = require './lib/utils'

getDirScripts = (dirPath, cb) ->
    fs.readdir dirPath, (err, files) ->
        return cb(err) if err?
        files = _.filter files, (f) ->
            path.extname(f).indexOf('js') isnt -1
        files = _.map files, (f) ->
            path.join dirPath, f
        cb null, files

inDest = (fileName) ->
    path.join __dirname, 'tmp/dest', fileName

mapDest = (filePath) ->
    noSrc = (x) ->
        _src = 'src/'
        x.substring( x.indexOf(_src) + _src.length )
    rel = noSrc(filePath)
    inDest rel

processFile = (processFn, filePath, cb) ->
    fs.readFile filePath, 'utf8', (err, res) ->
        return cb(err) if err?
        processFn res, filePath, (err, processed) ->
            return cb(err) if err?
            fs.writeFile mapDest(filePath), processed, (err) ->
                cb err

loadDir = (dirPath, cb) ->
    getDirScripts dirPath, (err, scripts) ->
        scripts = _.filter scripts, (f) ->
            path.basename(f).indexOf('_') isnt 0
        cb null, scripts



procOne = do ->
    {doUnAmd} = require './roc'

    asyncUnAmd = (src, filePath, cb) ->
        process.nextTick ->
            err = null
            result = null
            try
                result = doUnAmd(src)
            catch e
                err = e
                log 'ERR: ', filePath
            cb err, result

    (filePath, cb) ->
        processFile asyncUnAmd, filePath, cb


procAll = (scripts) ->
    async.each scripts, procOne, (err) ->
        throw err if err
        log '[done.]'


skipAll = do ->
    fn = (toSkip, toTest) ->
        _.filter toTest, (elem) ->
            _.all toSkip, (match) ->
                elem.indexOf(match) is -1

    _.curry(fn)


doMain = ->
    loadDir './tmp/src', (err, scripts) ->
        toSkip = ['main.js', 'tables.js']
        scripts = skipAll(toSkip, scripts)
        log scripts
        procAll scripts

doModels = ->
    loadDir './tmp/src/models', (err, scripts) ->
        log scripts
        procAll scripts

doTests = ->
    loadDir './tmp/src/test', (err, scripts) ->
        log scripts
        procAll scripts

doHelpers = ->
    loadDir './tmp/src/helperLib', (err, scripts) ->
        log scripts
        procAll scripts

# doTests()
# doMain()
# doModels()

doHelpers()

