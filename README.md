un-amd
=================

Convert AMD-style javascript modules to CommonJS, preserving comments and whitespace in the original code.

Currently beta, but the signature and behavior of the main exported `unAmd` function is unlikely to change.  More of the underlying functionality will be exposed at some point.

Installation
-----------------

    npm install un-amd


Example
-----------------

```coffeescript
{unAmd} = require 'un-amd'
fs = require 'fs'

script = fs.readFileSync './someScript.js', 'utf8'
result = unAmd script
fs.writeFileSync './result.js', result
console.log '[Done.]'
```

Contents of `someScript.js`:
```javascript
'use strict';

// a comment before the define call

define(['underscore', 'jquery', 'backbone'], function(_, $, Backbone) {
    
    var BaseModel = Backbone.Model.extend({
        setBad: function() {
            this._bad = true;
        },
        isGood: function() {
            return !this._bad;
        }
    });

    // a comment inside the define call

    var id = function(x) {
        return x;
    };

    return {
        BaseModel: BaseModel,
        id: id
    };

});
```

Contents of `result.js`:
```javascript
'use strict';

// a comment before the define call

var _ = require('underscore');
var $ = require('jquery');
var Backbone = require('backbone');

var BaseModel = Backbone.Model.extend({
    setBad: function() {
        this._bad = true;
    },
    isGood: function() {
        return !this._bad;
    }
});

// a comment inside the define call

var id = function(x) {
    return x;
};

module.exports = {
    BaseModel: BaseModel,
    id: id
};
```

Info
------------
__un-amd__ processes script files in three stages.

####Import/export resolution and code generation

This stage uses [an immutable wrapper](https://github.com/scivey/un-amd/blob/master/lib/ast.coffee) around a plain [esprima](https://github.com/ariya/esprima)-generated AST.  This structure is examined to find the module name and variable binding for each of the script's imports.  E.g. for:

```javascript
define(['underscore', 'jquery'], function(_, $) {
   // module code 
});
```
... the pairs `{jquery: '$'}` and `{underscore: '_'}` are extracted.  These are then manipulated into `require`-style imports:

```javascript
var _ = require('underscore');
var $ = require('jquery');
```

Next, the module's exports are resolved by searching for the last `ReturnStatement` that is a direct child of the `FunctionExpression` passed as an argument to `define`.

```javascript
define(['underscore'], function(_) {
    // module code
    return {
        someFunction: someFunction
    }; 
});
```

If a matching statement is detected, the return value is manipulated into a CommonJS-style export:
```javascript
module.exports = {
    someFunction: someFunction
};
```

####Extraction of module body tokens

This stage uses a tree produced by [rocambole](https://github.com/millermedeiros/rocambole), which extends the Esprima AST by linking nodes with their tokens.  This makes it easy to obtain the raw source for a given feature of the AST.  The drawback is that rocambole's structure is highly circular, so an immutable wrapper around it would be much more complicated to create than the vanilla esprima wrapper used in the first stage.

This tree is traversed to locate the node of the module body, defined as the body of the first `FunctionExpression` passed as an argument to a `CallExpression` where `callee.name` is equal to `define`.  The starting token of the module body is equal to `startingToken.next` of this AST node.

If that `FunctionExpression` contains a top-level `ReturnStatement`, then the stopping token is equal to `startingToken.prev` of the `ReturnStatement` node.  Otherwise, the stopping token is equal to `endingToken.prev` of the `FunctionExpression`.

The whole sequence of tokens between the start and end is then extracted and concatenated, yielding the main source of the module.

####Concatenation and reformatting

This stage uses the inefficient but simple approach of concatenating the results of the previous stages, re-parsing the source with `rocambole` and then ensuring consistent indentation by passing the tree to `esformatter`.



License
------------
MIT License (MIT)

Copyright (c) 2014 Scott Ivey, <scott.ivey@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.