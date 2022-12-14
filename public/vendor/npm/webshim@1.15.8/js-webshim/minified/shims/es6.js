/* */ 
(function(process) {
  webshim.register("es6", function(a, b, c, d, e) {
    "use strict";
    var f = function(a) {
      try {
        a();
      } catch (b) {
        return !1;
      }
      return !0;
    },
        g = function(a, b) {
          try {
            var c = function() {
              a.apply(this, arguments);
            };
            return c.__proto__ ? (Object.setPrototypeOf(c, a), c.prototype = Object.create(a.prototype, {constructor: {value: a}}), b(c)) : !1;
          } catch (d) {
            return !1;
          }
        },
        h = function() {
          try {
            return Object.defineProperty({}, "x", {}), !0;
          } catch (a) {
            return !1;
          }
        },
        i = function() {
          var a = !1;
          if (String.prototype.startsWith)
            try {
              "/a/".startsWith(/a/);
            } catch (b) {
              a = !0;
            }
          return a;
        },
        j = new Function("return this;"),
        k = function() {
          var a,
              b = j(),
              d = b.isFinite,
              k = !!Object.defineProperty && h(),
              l = i(),
              m = Array.prototype.slice,
              n = String.prototype.indexOf,
              o = Object.prototype.toString,
              p = Object.prototype.hasOwnProperty,
              q = function(a, b) {
                Object.keys(b).forEach(function(c) {
                  var d = b[c];
                  c in a || (k ? Object.defineProperty(a, c, {
                    configurable: !0,
                    enumerable: !1,
                    writable: !0,
                    value: d
                  }) : a[c] = d);
                });
              },
              r = Object.create || function(a, b) {
                function c() {}
                c.prototype = a;
                var d = new c;
                return "undefined" != typeof b && q(d, b), d;
              },
              s = "function" == typeof Symbol && Symbol.iterator || "_es6shim_iterator_";
          b.Set && "function" == typeof(new b.Set)["@@iterator"] && (s = "@@iterator");
          var t = function(a, b) {
            b || (b = function() {
              return this;
            });
            var c = {};
            c[s] = b, q(a, c);
          },
              u = function(a) {
                var b = o.call(a),
                    c = "[object Arguments]" === b;
                return c || (c = "[object Array]" !== b && null !== a && "object" == typeof a && "number" == typeof a.length && a.length >= 0 && "[object Function]" === o.call(a.callee)), c;
              },
              v = function(a) {
                if (!w.TypeIsObject(a))
                  throw new TypeError("bad object");
                return a._es6construct || (a.constructor && w.IsCallable(a.constructor["@@create"]) && (a = a.constructor["@@create"](a)), q(a, {_es6construct: !0})), a;
              },
              w = {
                CheckObjectCoercible: function(a, b) {
                  if (null == a)
                    throw new TypeError(b || "Cannot call method on " + a);
                  return a;
                },
                TypeIsObject: function(a) {
                  return null != a && Object(a) === a;
                },
                ToObject: function(a, b) {
                  return Object(w.CheckObjectCoercible(a, b));
                },
                IsCallable: function(a) {
                  return "function" == typeof a && "[object Function]" === o.call(a);
                },
                ToInt32: function(a) {
                  return a >> 0;
                },
                ToUint32: function(a) {
                  return a >>> 0;
                },
                ToInteger: function(a) {
                  var b = +a;
                  return Number.isNaN(b) ? 0 : 0 !== b && Number.isFinite(b) ? Math.sign(b) * Math.floor(Math.abs(b)) : b;
                },
                ToLength: function(a) {
                  var b = w.ToInteger(a);
                  return 0 >= b ? 0 : b > Number.MAX_SAFE_INTEGER ? Number.MAX_SAFE_INTEGER : b;
                },
                SameValue: function(a, b) {
                  return a === b ? 0 === a ? 1 / a === 1 / b : !0 : Number.isNaN(a) && Number.isNaN(b);
                },
                SameValueZero: function(a, b) {
                  return a === b || Number.isNaN(a) && Number.isNaN(b);
                },
                IsIterable: function(a) {
                  return w.TypeIsObject(a) && (a[s] !== e || u(a));
                },
                GetIterator: function(b) {
                  if (u(b))
                    return new a(b, "value");
                  var c = b[s]();
                  if (!w.TypeIsObject(c))
                    throw new TypeError("bad iterator");
                  return c;
                },
                IteratorNext: function(a) {
                  var b = arguments.length > 1 ? a.next(arguments[1]) : a.next();
                  if (!w.TypeIsObject(b))
                    throw new TypeError("bad iterator");
                  return b;
                },
                Construct: function(a, b) {
                  var c;
                  c = w.IsCallable(a["@@create"]) ? a["@@create"]() : r(a.prototype || null), q(c, {_es6construct: !0});
                  var d = a.apply(c, b);
                  return w.TypeIsObject(d) ? d : c;
                }
              },
              x = function() {
                function a(a) {
                  var b = Math.floor(a),
                      c = a - b;
                  return .5 > c ? b : c > .5 ? b + 1 : b % 2 ? b + 1 : b;
                }
                function b(b, c, d) {
                  var e,
                      f,
                      g,
                      h,
                      i,
                      j,
                      k,
                      l = (1 << c - 1) - 1;
                  for (b !== b ? (f = (1 << c) - 1, g = Math.pow(2, d - 1), e = 0) : 1 / 0 === b || b === -1 / 0 ? (f = (1 << c) - 1, g = 0, e = 0 > b ? 1 : 0) : 0 === b ? (f = 0, g = 0, e = 1 / b === -1 / 0 ? 1 : 0) : (e = 0 > b, b = Math.abs(b), b >= Math.pow(2, 1 - l) ? (f = Math.min(Math.floor(Math.log(b) / Math.LN2), 1023), g = a(b / Math.pow(2, f) * Math.pow(2, d)), g / Math.pow(2, d) >= 2 && (f += 1, g = 1), f > l ? (f = (1 << c) - 1, g = 0) : (f += l, g -= Math.pow(2, d))) : (f = 0, g = a(b / Math.pow(2, 1 - l - d)))), i = [], h = d; h; h -= 1)
                    i.push(g % 2 ? 1 : 0), g = Math.floor(g / 2);
                  for (h = c; h; h -= 1)
                    i.push(f % 2 ? 1 : 0), f = Math.floor(f / 2);
                  for (i.push(e ? 1 : 0), i.reverse(), j = i.join(""), k = []; j.length; )
                    k.push(parseInt(j.slice(0, 8), 2)), j = j.slice(8);
                  return k;
                }
                function c(a, b, c) {
                  var d,
                      e,
                      f,
                      g,
                      h,
                      i,
                      j,
                      k,
                      l = [];
                  for (d = a.length; d; d -= 1)
                    for (f = a[d - 1], e = 8; e; e -= 1)
                      l.push(f % 2 ? 1 : 0), f >>= 1;
                  return l.reverse(), g = l.join(""), h = (1 << b - 1) - 1, i = parseInt(g.slice(0, 1), 2) ? -1 : 1, j = parseInt(g.slice(1, 1 + b), 2), k = parseInt(g.slice(1 + b), 2), j === (1 << b) - 1 ? 0 !== k ? 0 / 0 : 1 / 0 * i : j > 0 ? i * Math.pow(2, j - h) * (1 + k / Math.pow(2, c)) : 0 !== k ? i * Math.pow(2, -(h - 1)) * (k / Math.pow(2, c)) : 0 > i ? -0 : 0;
                }
                function d(a) {
                  return c(a, 8, 23);
                }
                function e(a) {
                  return b(a, 8, 23);
                }
                var f = {toFloat32: function(a) {
                    return d(e(a));
                  }};
                if ("undefined" != typeof Float32Array) {
                  var g = new Float32Array(1);
                  f.toFloat32 = function(a) {
                    return g[0] = a, g[0];
                  };
                }
                return f;
              }();
          q(String, {
            fromCodePoint: function() {
              for (var a,
                  b = m.call(arguments, 0, arguments.length),
                  c = [],
                  d = 0,
                  e = b.length; e > d; d++) {
                if (a = Number(b[d]), !w.SameValue(a, w.ToInteger(a)) || 0 > a || a > 1114111)
                  throw new RangeError("Invalid code point " + a);
                65536 > a ? c.push(String.fromCharCode(a)) : (a -= 65536, c.push(String.fromCharCode((a >> 10) + 55296)), c.push(String.fromCharCode(a % 1024 + 56320)));
              }
              return c.join("");
            },
            raw: function(a) {
              var b = m.call(arguments, 1, arguments.length),
                  c = w.ToObject(a, "bad callSite"),
                  d = c.raw,
                  f = w.ToObject(d, "bad raw value"),
                  g = Object.keys(f).length,
                  h = w.ToLength(g);
              if (0 === h)
                return "";
              for (var i,
                  j,
                  k,
                  l,
                  n = [],
                  o = 0; h > o && (i = String(o), j = f[i], k = String(j), n.push(k), !(o + 1 >= h)) && (j = b[i], j !== e); )
                l = String(j), n.push(l), o++;
              return n.join("");
            }
          });
          var y = {
            repeat: function() {
              var a = function(b, c) {
                if (1 > c)
                  return "";
                if (c % 2)
                  return a(b, c - 1) + b;
                var d = a(b, c / 2);
                return d + d;
              };
              return function(b) {
                var c = String(w.CheckObjectCoercible(this));
                if (b = w.ToInteger(b), 0 > b || 1 / 0 === b)
                  throw new RangeError("Invalid String#repeat value");
                return a(c, b);
              };
            }(),
            startsWith: function(a) {
              var b = String(w.CheckObjectCoercible(this));
              if ("[object RegExp]" === o.call(a))
                throw new TypeError('Cannot call method "startsWith" with a regex');
              a = String(a);
              var c = arguments.length > 1 ? arguments[1] : e,
                  d = Math.max(w.ToInteger(c), 0);
              return b.slice(d, d + a.length) === a;
            },
            endsWith: function(a) {
              var b = String(w.CheckObjectCoercible(this));
              if ("[object RegExp]" === o.call(a))
                throw new TypeError('Cannot call method "endsWith" with a regex');
              a = String(a);
              var c = b.length,
                  d = arguments.length > 1 ? arguments[1] : e,
                  f = d === e ? c : w.ToInteger(d),
                  g = Math.min(Math.max(f, 0), c);
              return b.slice(g - a.length, g) === a;
            },
            contains: function(a) {
              var b = arguments.length > 1 ? arguments[1] : e;
              return -1 !== n.call(this, a, b);
            },
            codePointAt: function(a) {
              var b = String(w.CheckObjectCoercible(this)),
                  c = w.ToInteger(a),
                  d = b.length;
              if (0 > c || c >= d)
                return e;
              var f = b.charCodeAt(c),
                  g = c + 1 === d;
              if (55296 > f || f > 56319 || g)
                return f;
              var h = b.charCodeAt(c + 1);
              return 56320 > h || h > 57343 ? f : 1024 * (f - 55296) + (h - 56320) + 65536;
            }
          };
          q(String.prototype, y);
          var z = 1 !== "\x85".trim().length;
          if (z) {
            {
              String.prototype.trim;
            }
            delete String.prototype.trim;
            var A = ["	\n\f\r \xa0\u1680\u180e\u2000\u2001\u2002\u2003", "\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028", "\u2029\ufeff"].join(""),
                B = new RegExp("^[" + A + "][" + A + "]*"),
                C = new RegExp("[" + A + "][" + A + "]*$");
            q(String.prototype, {trim: function() {
                if (this === e || null === this)
                  throw new TypeError("can't convert " + this + " to object");
                return String(this).replace(B, "").replace(C, "");
              }});
          }
          var D = function(a) {
            this._s = String(w.CheckObjectCoercible(a)), this._i = 0;
          };
          D.prototype.next = function() {
            var a = this._s,
                b = this._i;
            if (a === e || b >= a.length)
              return this._s = e, {
                value: e,
                done: !0
              };
            var c,
                d,
                f = a.charCodeAt(b);
            return 55296 > f || f > 56319 || b + 1 == a.length ? d = 1 : (c = a.charCodeAt(b + 1), d = 56320 > c || c > 57343 ? 1 : 2), this._i = b + d, {
              value: a.substr(b, d),
              done: !1
            };
          }, t(D.prototype), t(String.prototype, function() {
            return new D(this);
          }), l || (String.prototype.startsWith = y.startsWith, String.prototype.endsWith = y.endsWith), q(Array, {
            from: function(a) {
              var b = arguments.length > 1 ? arguments[1] : e,
                  c = arguments.length > 2 ? arguments[2] : e,
                  d = w.ToObject(a, "bad iterable");
              if (b !== e && !w.IsCallable(b))
                throw new TypeError("Array.from: when provided, the second argument must be a function");
              for (var f,
                  g = w.IsIterable(d),
                  h = g ? 0 : w.ToLength(d.length),
                  i = w.IsCallable(this) ? Object(g ? new this : new this(h)) : new Array(h),
                  j = g ? w.GetIterator(d) : null,
                  k = 0; g || h > k; k++) {
                if (g) {
                  if (f = w.IteratorNext(j), f.done) {
                    h = k;
                    break;
                  }
                  f = f.value;
                } else
                  f = d[k];
                i[k] = b ? c ? b.call(c, f, k) : b(f, k) : f;
              }
              return i.length = h, i;
            },
            of: function() {
              return Array.from(arguments);
            }
          }), a = function(a, b) {
            this.i = 0, this.array = a, this.kind = b;
          }, q(a.prototype, {next: function() {
              var a = this.i,
                  b = this.array;
              if (a === e || this.kind === e)
                throw new TypeError("Not an ArrayIterator");
              if (b !== e)
                for (var c = w.ToLength(b.length); c > a; a++) {
                  var d,
                      f = this.kind;
                  return "key" === f ? d = a : "value" === f ? d = b[a] : "entry" === f && (d = [a, b[a]]), this.i = a + 1, {
                    value: d,
                    done: !1
                  };
                }
              return this.array = e, {
                value: e,
                done: !0
              };
            }}), t(a.prototype), q(Array.prototype, {
            copyWithin: function(a, b) {
              var c = arguments[2],
                  d = w.ToObject(this),
                  f = w.ToLength(d.length);
              a = w.ToInteger(a), b = w.ToInteger(b);
              var g = 0 > a ? Math.max(f + a, 0) : Math.min(a, f),
                  h = 0 > b ? Math.max(f + b, 0) : Math.min(b, f);
              c = c === e ? f : w.ToInteger(c);
              var i = 0 > c ? Math.max(f + c, 0) : Math.min(c, f),
                  j = Math.min(i - h, f - g),
                  k = 1;
              for (g > h && h + j > g && (k = -1, h += j - 1, g += j - 1); j > 0; )
                p.call(d, h) ? d[g] = d[h] : delete d[h], h += k, g += k, j -= 1;
              return d;
            },
            fill: function(a) {
              var b = arguments.length > 1 ? arguments[1] : e,
                  c = arguments.length > 2 ? arguments[2] : e,
                  d = w.ToObject(this),
                  f = w.ToLength(d.length);
              b = w.ToInteger(b === e ? 0 : b), c = w.ToInteger(c === e ? f : c);
              for (var g = 0 > b ? Math.max(f + b, 0) : Math.min(b, f),
                  h = 0 > c ? f + c : c,
                  i = g; f > i && h > i; ++i)
                d[i] = a;
              return d;
            },
            find: function(a) {
              var b = w.ToObject(this),
                  c = w.ToLength(b.length);
              if (!w.IsCallable(a))
                throw new TypeError("Array#find: predicate must be a function");
              for (var d,
                  f = arguments[1],
                  g = 0; c > g; g++)
                if (g in b && (d = b[g], a.call(f, d, g, b)))
                  return d;
              return e;
            },
            findIndex: function(a) {
              var b = w.ToObject(this),
                  c = w.ToLength(b.length);
              if (!w.IsCallable(a))
                throw new TypeError("Array#findIndex: predicate must be a function");
              for (var d = arguments[1],
                  e = 0; c > e; e++)
                if (e in b && a.call(d, b[e], e, b))
                  return e;
              return -1;
            },
            keys: function() {
              return new a(this, "key");
            },
            values: function() {
              return new a(this, "value");
            },
            entries: function() {
              return new a(this, "entry");
            }
          }), t(Array.prototype, function() {
            return this.values();
          }), Object.getPrototypeOf && t(Object.getPrototypeOf([].values()));
          var E = Math.pow(2, 53) - 1;
          q(Number, {
            MAX_SAFE_INTEGER: E,
            MIN_SAFE_INTEGER: -E,
            EPSILON: 2.220446049250313e-16,
            parseInt: b.parseInt,
            parseFloat: b.parseFloat,
            isFinite: function(a) {
              return "number" == typeof a && d(a);
            },
            isInteger: function(a) {
              return Number.isFinite(a) && w.ToInteger(a) === a;
            },
            isSafeInteger: function(a) {
              return Number.isInteger(a) && Math.abs(a) <= Number.MAX_SAFE_INTEGER;
            },
            isNaN: function(a) {
              return a !== a;
            }
          }), k && (q(Object, {
            getPropertyDescriptor: function(a, b) {
              for (var c = Object.getOwnPropertyDescriptor(a, b),
                  d = Object.getPrototypeOf(a); c === e && null !== d; )
                c = Object.getOwnPropertyDescriptor(d, b), d = Object.getPrototypeOf(d);
              return c;
            },
            getPropertyNames: function(a) {
              for (var b = Object.getOwnPropertyNames(a),
                  c = Object.getPrototypeOf(a),
                  d = function(a) {
                    -1 === b.indexOf(a) && b.push(a);
                  }; null !== c; )
                Object.getOwnPropertyNames(c).forEach(d), c = Object.getPrototypeOf(c);
              return b;
            }
          }), q(Object, {
            assign: function(a) {
              if (!w.TypeIsObject(a))
                throw new TypeError("target must be an object");
              return Array.prototype.reduce.call(arguments, function(a, b) {
                return Object.keys(Object(b)).reduce(function(a, c) {
                  return a[c] = b[c], a;
                }, a);
              });
            },
            is: function(a, b) {
              return w.SameValue(a, b);
            },
            setPrototypeOf: function(a, b) {
              var c,
                  d = function(a, b) {
                    if (!w.TypeIsObject(a))
                      throw new TypeError("cannot set prototype on a non-object");
                    if (null !== b && !w.TypeIsObject(b))
                      throw new TypeError("can only set prototype to an object or null" + b);
                  },
                  e = function(a, b) {
                    return d(a, b), c.call(a, b), a;
                  };
              try {
                c = a.getOwnPropertyDescriptor(a.prototype, b).set, c.call({}, null);
              } catch (f) {
                if (a.prototype !== {}[b])
                  return;
                c = function(a) {
                  this[b] = a;
                }, e.polyfill = e(e({}, null), a.prototype) instanceof a;
              }
              return e;
            }(Object, "__proto__")
          })), Object.setPrototypeOf && Object.getPrototypeOf && null !== Object.getPrototypeOf(Object.setPrototypeOf({}, null)) && null === Object.getPrototypeOf(Object.create(null)) && !function() {
            var a = Object.create(null),
                b = Object.getPrototypeOf,
                c = Object.setPrototypeOf;
            Object.getPrototypeOf = function(c) {
              var d = b(c);
              return d === a ? null : d;
            }, Object.setPrototypeOf = function(b, d) {
              return null === d && (d = a), c(b, d);
            }, Object.setPrototypeOf.polyfill = !1;
          }();
          try {
            Object.keys("foo");
          } catch (F) {
            var G = Object.keys;
            Object.keys = function(a) {
              return G(w.ToObject(a));
            };
          }
          var H = {
            acosh: function(a) {
              return a = Number(a), Number.isNaN(a) || 1 > a ? 0 / 0 : 1 === a ? 0 : 1 / 0 === a ? a : Math.log(a + Math.sqrt(a * a - 1));
            },
            asinh: function(a) {
              return a = Number(a), 0 !== a && d(a) ? 0 > a ? -Math.asinh(-a) : Math.log(a + Math.sqrt(a * a + 1)) : a;
            },
            atanh: function(a) {
              return a = Number(a), Number.isNaN(a) || -1 > a || a > 1 ? 0 / 0 : -1 === a ? -1 / 0 : 1 === a ? 1 / 0 : 0 === a ? a : .5 * Math.log((1 + a) / (1 - a));
            },
            cbrt: function(a) {
              if (a = Number(a), 0 === a)
                return a;
              var b,
                  c = 0 > a;
              return c && (a = -a), b = Math.pow(a, 1 / 3), c ? -b : b;
            },
            clz32: function(a) {
              a = Number(a);
              var b = w.ToUint32(a);
              return 0 === b ? 32 : 32 - b.toString(2).length;
            },
            cosh: function(a) {
              return a = Number(a), 0 === a ? 1 : Number.isNaN(a) ? 0 / 0 : d(a) ? (0 > a && (a = -a), a > 21 ? Math.exp(a) / 2 : (Math.exp(a) + Math.exp(-a)) / 2) : 1 / 0;
            },
            expm1: function(a) {
              return a = Number(a), a === -1 / 0 ? -1 : d(a) && 0 !== a ? Math.exp(a) - 1 : a;
            },
            hypot: function() {
              var a = !1,
                  b = !0,
                  c = !1,
                  d = [];
              if (Array.prototype.every.call(arguments, function(e) {
                var f = Number(e);
                return Number.isNaN(f) ? a = !0 : 1 / 0 === f || f === -1 / 0 ? c = !0 : 0 !== f && (b = !1), c ? !1 : (a || d.push(Math.abs(f)), !0);
              }), c)
                return 1 / 0;
              if (a)
                return 0 / 0;
              if (b)
                return 0;
              d.sort(function(a, b) {
                return b - a;
              });
              var e = d[0],
                  f = d.map(function(a) {
                    return a / e;
                  }),
                  g = f.reduce(function(a, b) {
                    return a += b * b;
                  }, 0);
              return e * Math.sqrt(g);
            },
            log2: function(a) {
              return Math.log(a) * Math.LOG2E;
            },
            log10: function(a) {
              return Math.log(a) * Math.LOG10E;
            },
            log1p: function(a) {
              if (a = Number(a), -1 > a || Number.isNaN(a))
                return 0 / 0;
              if (0 === a || 1 / 0 === a)
                return a;
              if (-1 === a)
                return -1 / 0;
              var b = 0,
                  c = 50;
              if (0 > a || a > 1)
                return Math.log(1 + a);
              for (var d = 1; c > d; d++)
                d % 2 === 0 ? b -= Math.pow(a, d) / d : b += Math.pow(a, d) / d;
              return b;
            },
            sign: function(a) {
              var b = +a;
              return 0 === b ? b : Number.isNaN(b) ? b : 0 > b ? -1 : 1;
            },
            sinh: function(a) {
              return a = Number(a), d(a) && 0 !== a ? (Math.exp(a) - Math.exp(-a)) / 2 : a;
            },
            tanh: function(a) {
              return a = Number(a), Number.isNaN(a) || 0 === a ? a : 1 / 0 === a ? 1 : a === -1 / 0 ? -1 : (Math.exp(a) - Math.exp(-a)) / (Math.exp(a) + Math.exp(-a));
            },
            trunc: function(a) {
              var b = Number(a);
              return 0 > b ? -Math.floor(-b) : Math.floor(b);
            },
            imul: function(a, b) {
              a = w.ToUint32(a), b = w.ToUint32(b);
              var c = a >>> 16 & 65535,
                  d = 65535 & a,
                  e = b >>> 16 & 65535,
                  f = 65535 & b;
              return d * f + (c * f + d * e << 16 >>> 0) | 0;
            },
            fround: function(a) {
              if (0 === a || 1 / 0 === a || a === -1 / 0 || Number.isNaN(a))
                return a;
              var b = Number(a);
              return x.toFloat32(b);
            }
          };
          q(Math, H), -5 !== Math.imul(4294967295, 5) && (Math.imul = H.imul);
          var I = function() {
            var a,
                d;
            w.IsPromise = function(a) {
              return w.TypeIsObject(a) && a._promiseConstructor ? a._status === e ? !1 : !0 : !1;
            };
            var f,
                g = function(a) {
                  if (!w.IsCallable(a))
                    throw new TypeError("bad promise constructor");
                  var b = this,
                      c = function(a, c) {
                        b.resolve = a, b.reject = c;
                      };
                  if (b.promise = w.Construct(a, [c]), !b.promise._es6construct)
                    throw new TypeError("bad promise constructor");
                  if (!w.IsCallable(b.resolve) || !w.IsCallable(b.reject))
                    throw new TypeError("bad promise constructor");
                },
                h = b.setTimeout;
            "undefined" != typeof c && w.IsCallable(c.postMessage) && (f = function() {
              var a = [],
                  b = "zero-timeout-message",
                  d = function(d) {
                    a.push(d), c.postMessage(b, "*");
                  },
                  e = function(d) {
                    if (d.source == c && d.data == b) {
                      if (d.stopPropagation(), 0 === a.length)
                        return;
                      var e = a.shift();
                      e();
                    }
                  };
              return c.addEventListener("message", e, !0), d;
            });
            var i = function() {
              var a = b.Promise;
              return a && a.resolve && function(b) {
                return a.resolve().then(b);
              };
            },
                j = w.IsCallable(b.setImmediate) ? b.setImmediate.bind(b) : "object" == typeof process && process.nextTick ? process.nextTick : i() || (w.IsCallable(f) ? f() : function(a) {
                  h(a, 0);
                }),
                k = function(a, b) {
                  a.forEach(function(a) {
                    j(function() {
                      var c = a.handler,
                          d = a.capability,
                          e = d.resolve,
                          f = d.reject;
                      try {
                        var g = c(b);
                        if (g === d.promise)
                          throw new TypeError("self resolution");
                        var h = l(g, d);
                        h || e(g);
                      } catch (i) {
                        f(i);
                      }
                    });
                  });
                },
                l = function(a, b) {
                  if (!w.TypeIsObject(a))
                    return !1;
                  var c = b.resolve,
                      d = b.reject;
                  try {
                    var e = a.then;
                    if (!w.IsCallable(e))
                      return !1;
                    e.call(a, c, d);
                  } catch (f) {
                    d(f);
                  }
                  return !0;
                },
                m = function(a, b, c) {
                  return function(d) {
                    if (d === a)
                      return c(new TypeError("self resolution"));
                    var e = a._promiseConstructor,
                        f = new g(e),
                        h = l(d, f);
                    return h ? f.promise.then(b, c) : b(d);
                  };
                };
            a = function(a) {
              var b = this;
              if (b = v(b), !b._promiseConstructor)
                throw new TypeError("bad promise");
              if (b._status !== e)
                throw new TypeError("promise already initialized");
              if (!w.IsCallable(a))
                throw new TypeError("not a valid resolver");
              b._status = "unresolved", b._resolveReactions = [], b._rejectReactions = [];
              var c = function(a) {
                if ("unresolved" === b._status) {
                  var c = b._resolveReactions;
                  b._result = a, b._resolveReactions = e, b._rejectReactions = e, b._status = "has-resolution", k(c, a);
                }
              },
                  d = function(a) {
                    if ("unresolved" === b._status) {
                      var c = b._rejectReactions;
                      b._result = a, b._resolveReactions = e, b._rejectReactions = e, b._status = "has-rejection", k(c, a);
                    }
                  };
              try {
                a(c, d);
              } catch (f) {
                d(f);
              }
              return b;
            }, d = a.prototype, q(a, {"@@create": function(a) {
                var b = this,
                    c = b.prototype || d;
                return a = a || r(c), q(a, {
                  _status: e,
                  _result: e,
                  _resolveReactions: e,
                  _rejectReactions: e,
                  _promiseConstructor: e
                }), a._promiseConstructor = b, a;
              }});
            var n = function(a, b, c, d) {
              var e = !1;
              return function(f) {
                if (!e && (e = !0, b[a] = f, 0 === --d.count)) {
                  var g = c.resolve;
                  g(b);
                }
              };
            };
            return a.all = function(a) {
              var b = this,
                  c = new g(b),
                  d = c.resolve,
                  e = c.reject;
              try {
                if (!w.IsIterable(a))
                  throw new TypeError("bad iterable");
                for (var f = w.GetIterator(a),
                    h = [],
                    i = {count: 1},
                    j = 0; ; j++) {
                  var k = w.IteratorNext(f);
                  if (k.done)
                    break;
                  var l = b.resolve(k.value),
                      m = n(j, h, c, i);
                  i.count++, l.then(m, c.reject);
                }
                0 === --i.count && d(h);
              } catch (o) {
                e(o);
              }
              return c.promise;
            }, a.race = function(a) {
              var b = this,
                  c = new g(b),
                  d = c.resolve,
                  e = c.reject;
              try {
                if (!w.IsIterable(a))
                  throw new TypeError("bad iterable");
                for (var f = w.GetIterator(a); ; ) {
                  var h = w.IteratorNext(f);
                  if (h.done)
                    break;
                  var i = b.resolve(h.value);
                  i.then(d, e);
                }
              } catch (j) {
                e(j);
              }
              return c.promise;
            }, a.reject = function(a) {
              var b = this,
                  c = new g(b),
                  d = c.reject;
              return d(a), c.promise;
            }, a.resolve = function(a) {
              var b = this;
              if (w.IsPromise(a)) {
                var c = a._promiseConstructor;
                if (c === b)
                  return a;
              }
              var d = new g(b),
                  e = d.resolve;
              return e(a), d.promise;
            }, a.prototype["catch"] = function(a) {
              return this.then(e, a);
            }, a.prototype.then = function(a, b) {
              var c = this;
              if (!w.IsPromise(c))
                throw new TypeError("not a promise");
              var d = this.constructor,
                  e = new g(d);
              w.IsCallable(b) || (b = function(a) {
                throw a;
              }), w.IsCallable(a) || (a = function(a) {
                return a;
              });
              var f = m(c, a, b),
                  h = {
                    capability: e,
                    handler: f
                  },
                  i = {
                    capability: e,
                    handler: b
                  };
              switch (c._status) {
                case "unresolved":
                  c._resolveReactions.push(h), c._rejectReactions.push(i);
                  break;
                case "has-resolution":
                  k([h], c._result);
                  break;
                case "has-rejection":
                  k([i], c._result);
                  break;
                default:
                  throw new TypeError("unexpected");
              }
              return e.promise;
            }, a;
          }();
          q(b, {Promise: I});
          var J = g(b.Promise, function(a) {
            return a.resolve(42) instanceof a;
          }),
              K = function() {
                try {
                  return b.Promise.reject(42).then(null, 5).then(null, function() {}), !0;
                } catch (a) {
                  return !1;
                }
              }();
          if (J && K || (b.Promise = I), k) {
            var L = function(a) {
              var b = typeof a;
              return "string" === b ? "$" + a : "number" === b ? a : null;
            },
                M = function() {
                  return Object.create ? Object.create(null) : {};
                },
                N = {
                  Map: function() {
                    function a(a, b) {
                      this.key = a, this.value = b, this.next = null, this.prev = null;
                    }
                    function b(a, b) {
                      this.head = a._head, this.i = this.head, this.kind = b;
                    }
                    function c(b) {
                      var c = this;
                      if (c = v(c), !c._es6map)
                        throw new TypeError("bad map");
                      var d = new a(null, null);
                      if (d.next = d.prev = d, q(c, {
                        _head: d,
                        _storage: M(),
                        _size: 0
                      }), b !== e && null !== b) {
                        var f = w.GetIterator(b),
                            g = c.set;
                        if (!w.IsCallable(g))
                          throw new TypeError("bad map");
                        for (; ; ) {
                          var h = w.IteratorNext(f);
                          if (h.done)
                            break;
                          var i = h.value;
                          if (!w.TypeIsObject(i))
                            throw new TypeError("expected iterable of pairs");
                          g.call(c, i[0], i[1]);
                        }
                      }
                      return c;
                    }
                    var d = {};
                    a.prototype.isRemoved = function() {
                      return this.key === d;
                    }, b.prototype = {next: function() {
                        var a,
                            b = this.i,
                            c = this.kind,
                            d = this.head;
                        if (this.i === e)
                          return {
                            value: e,
                            done: !0
                          };
                        for (; b.isRemoved() && b !== d; )
                          b = b.prev;
                        for (; b.next !== d; )
                          if (b = b.next, !b.isRemoved())
                            return a = "key" === c ? b.key : "value" === c ? b.value : [b.key, b.value], this.i = b, {
                              value: a,
                              done: !1
                            };
                        return this.i = e, {
                          value: e,
                          done: !0
                        };
                      }}, t(b.prototype);
                    var f = c.prototype;
                    return q(c, {"@@create": function(a) {
                        var b = this,
                            c = b.prototype || f;
                        return a = a || r(c), q(a, {_es6map: !0}), a;
                      }}), Object.defineProperty(c.prototype, "size", {
                      configurable: !0,
                      enumerable: !1,
                      get: function() {
                        if ("undefined" == typeof this._size)
                          throw new TypeError("size method called on incompatible Map");
                        return this._size;
                      }
                    }), q(c.prototype, {
                      get: function(a) {
                        var b = L(a);
                        if (null !== b) {
                          var c = this._storage[b];
                          return c ? c.value : e;
                        }
                        for (var d = this._head,
                            f = d; (f = f.next) !== d; )
                          if (w.SameValueZero(f.key, a))
                            return f.value;
                        return e;
                      },
                      has: function(a) {
                        var b = L(a);
                        if (null !== b)
                          return "undefined" != typeof this._storage[b];
                        for (var c = this._head,
                            d = c; (d = d.next) !== c; )
                          if (w.SameValueZero(d.key, a))
                            return !0;
                        return !1;
                      },
                      set: function(b, c) {
                        var d,
                            e = this._head,
                            f = e,
                            g = L(b);
                        if (null !== g) {
                          if ("undefined" != typeof this._storage[g])
                            return void(this._storage[g].value = c);
                          d = this._storage[g] = new a(b, c), f = e.prev;
                        }
                        for (; (f = f.next) !== e; )
                          if (w.SameValueZero(f.key, b))
                            return void(f.value = c);
                        d = d || new a(b, c), w.SameValue(-0, b) && (d.key = 0), d.next = this._head, d.prev = this._head.prev, d.prev.next = d, d.next.prev = d, this._size += 1;
                      },
                      "delete": function(a) {
                        var b = this._head,
                            c = b,
                            e = L(a);
                        if (null !== e) {
                          if ("undefined" == typeof this._storage[e])
                            return !1;
                          c = this._storage[e].prev, delete this._storage[e];
                        }
                        for (; (c = c.next) !== b; )
                          if (w.SameValueZero(c.key, a))
                            return c.key = c.value = d, c.prev.next = c.next, c.next.prev = c.prev, this._size -= 1, !0;
                        return !1;
                      },
                      clear: function() {
                        this._size = 0, this._storage = M();
                        for (var a = this._head,
                            b = a,
                            c = b.next; (b = c) !== a; )
                          b.key = b.value = d, c = b.next, b.next = b.prev = a;
                        a.next = a.prev = a;
                      },
                      keys: function() {
                        return new b(this, "key");
                      },
                      values: function() {
                        return new b(this, "value");
                      },
                      entries: function() {
                        return new b(this, "key+value");
                      },
                      forEach: function(a) {
                        for (var b = arguments.length > 1 ? arguments[1] : null,
                            c = this.entries(),
                            d = c.next(); !d.done; d = c.next())
                          a.call(b, d.value[1], d.value[0], this);
                      }
                    }), t(c.prototype, function() {
                      return this.entries();
                    }), c;
                  }(),
                  Set: function() {
                    var a = function(a) {
                      var b = this;
                      if (b = v(b), !b._es6set)
                        throw new TypeError("bad set");
                      if (q(b, {
                        "[[SetData]]": null,
                        _storage: M()
                      }), a !== e && null !== a) {
                        var c = w.GetIterator(a),
                            d = b.add;
                        if (!w.IsCallable(d))
                          throw new TypeError("bad set");
                        for (; ; ) {
                          var f = w.IteratorNext(c);
                          if (f.done)
                            break;
                          var g = f.value;
                          d.call(b, g);
                        }
                      }
                      return b;
                    },
                        b = a.prototype;
                    q(a, {"@@create": function(a) {
                        var c = this,
                            d = c.prototype || b;
                        return a = a || r(d), q(a, {_es6set: !0}), a;
                      }});
                    var c = function(a) {
                      if (!a["[[SetData]]"]) {
                        var b = a["[[SetData]]"] = new N.Map;
                        Object.keys(a._storage).forEach(function(a) {
                          a = 36 === a.charCodeAt(0) ? a.slice(1) : +a, b.set(a, a);
                        }), a._storage = null;
                      }
                    };
                    return Object.defineProperty(a.prototype, "size", {
                      configurable: !0,
                      enumerable: !1,
                      get: function() {
                        if ("undefined" == typeof this._storage)
                          throw new TypeError("size method called on incompatible Set");
                        return c(this), this["[[SetData]]"].size;
                      }
                    }), q(a.prototype, {
                      has: function(a) {
                        var b;
                        return this._storage && null !== (b = L(a)) ? !!this._storage[b] : (c(this), this["[[SetData]]"].has(a));
                      },
                      add: function(a) {
                        var b;
                        return this._storage && null !== (b = L(a)) ? void(this._storage[b] = !0) : (c(this), this["[[SetData]]"].set(a, a));
                      },
                      "delete": function(a) {
                        var b;
                        return this._storage && null !== (b = L(a)) ? void delete this._storage[b] : (c(this), this["[[SetData]]"]["delete"](a));
                      },
                      clear: function() {
                        return this._storage ? void(this._storage = M()) : this["[[SetData]]"].clear();
                      },
                      keys: function() {
                        return c(this), this["[[SetData]]"].keys();
                      },
                      values: function() {
                        return c(this), this["[[SetData]]"].values();
                      },
                      entries: function() {
                        return c(this), this["[[SetData]]"].entries();
                      },
                      forEach: function(a) {
                        var b = arguments.length > 1 ? arguments[1] : null,
                            d = this;
                        c(this), this["[[SetData]]"].forEach(function(c, e) {
                          a.call(b, e, e, d);
                        });
                      }
                    }), t(a.prototype, function() {
                      return this.values();
                    }), a;
                  }()
                };
            q(b, N), (b.Map || b.Set) && ("function" != typeof b.Map.prototype.clear || 0 !== (new b.Set).size || 0 !== (new b.Map).size || "function" != typeof b.Map.prototype.keys || "function" != typeof b.Set.prototype.keys || "function" != typeof b.Map.prototype.forEach || "function" != typeof b.Set.prototype.forEach || f(b.Map) || f(b.Set) || !g(b.Map, function(a) {
              return new a([]) instanceof a;
            })) && (b.Map = N.Map, b.Set = N.Set), t(Object.getPrototypeOf((new b.Map).keys())), t(Object.getPrototypeOf((new b.Set).keys()));
          }
        };
    k();
  });
})(require('process'));
