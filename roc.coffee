rocambole = require 'rocambole'
m = require './lib/mWrap'
utils = require './lib/utils'
{inspect, log} = utils


src5 = """
define(['underscore', 'jquery'], function(_, $) {
    var x = Backbone.Model.extend({
        foo: function() {
            this._baz = true;
        }
    });

    // this is a comment
    var y = Backbone.Model.extend({
        bat: function() {
            this._bar = true;
        }
    });
    return {
        band: band
    };
});
"""

foo = rocambole.parse src5
console.log foo

