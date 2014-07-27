un-amd
=================

Convert AMD-style javascript modules to CommonJS, preserving comments and whitespace in the original code.

Currently beta, but the signature and behavior of the main exported `unAmd` function is unlikely to change.  More of the underlying functionality will be exposed at some point.

Installation
=================

    npm install un-amd


Example
=================

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