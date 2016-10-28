!(function(e) {
  if (typeof exports == 'object' && typeof module != 'undefined')
    module.exports = e()
  else if (typeof define == 'function' && define.amd) define([], e)
  else {
    var n
    typeof window != 'undefined' ? n = window : typeof global != 'undefined' ? n = global : typeof self != 'undefined' && (n = self), n.deepFreeze = e()
  }
}(function() {
  return (function e(n, r, o) {
    function t(i, u) {
      if (!r[i]) {
        if (!n[i]) {
          var c = typeof require == 'function' && require
          if (!u && c) return c(i, !0)
          if (f) return f(i, !0)
          var d = new Error("Cannot find module '" + i + "'")
          throw d.code = 'MODULE_NOT_FOUND', d
        }
        var p = r[i] = {
          exports: {}
        }
        n[i][0].call(p.exports, function(e) {
          var r = n[i][1][e]
          return t(r ? r : e)
        }, p, p.exports, e, n, r, o)
      }
      return r[i].exports
    }
    for (var f = typeof require == 'function' && require, i = 0; i < o.length; i++) t(o[i])
    return t
  }({
    1: [function(e, n, r) {
      n.exports = function o(e) {
        return Object.freeze(e), Object.getOwnPropertyNames(e).forEach(function(n) {
          !e.hasOwnProperty(n) || e[n] === null || typeof e[n] != 'object' && typeof e[n] != 'function' || Object.isFrozen(e[n]) || o(e[n])
        }), e
      }
    }, {}]
  }, {}, [1]))(1)
}))
