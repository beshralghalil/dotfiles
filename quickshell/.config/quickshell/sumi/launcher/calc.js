.pragma library
// 墨 launcher calculator ("=" prefix). The expression is tokenized against a
// whitelist (numbers, + - * / % ^ ( ) , and a few Math names) and rebuilt from
// those tokens only, so nothing but arithmetic ever reaches Function().
// Pure JS (no Qt types) for node tests.

var NAMES = {
    pi: "Math.PI", e: "Math.E", tau: "(2*Math.PI)",
    sqrt: "Math.sqrt", cbrt: "Math.cbrt", abs: "Math.abs",
    sin: "Math.sin", cos: "Math.cos", tan: "Math.tan",
    asin: "Math.asin", acos: "Math.acos", atan: "Math.atan",
    ln: "Math.log", log: "Math.log10", log2: "Math.log2", exp: "Math.exp",
    floor: "Math.floor", ceil: "Math.ceil", round: "Math.round",
    min: "Math.min", max: "Math.max", pow: "Math.pow"
};

// whole-string shape check first (cheap reject), then a strict tokenizer
var SHAPE = /^[0-9a-z+\-*/%^().,_\s×÷]*$/i;
var TOKEN = /\s*(?:(\d+(?:\.\d*)?(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([a-z][a-z0-9]*)|(\*\*|[+\-*/%^(),×÷]))/iy;

function compile(src) {
    var s = String(src).replace(/_/g, "");
    if (!SHAPE.test(s) || s.trim().length === 0)
        return null;
    var out = [];
    var depth = 0;
    TOKEN.lastIndex = 0;
    while (TOKEN.lastIndex < s.length) {
        if (/^\s*$/.test(s.slice(TOKEN.lastIndex)))
            break;
        var m = TOKEN.exec(s);
        if (!m)
            return null;
        if (m[1] !== undefined) {
            out.push(m[1]);
        } else if (m[2] !== undefined) {
            var name = m[2].toLowerCase();
            if (!NAMES.hasOwnProperty(name))
                return null;
            out.push(NAMES[name]);
        } else {
            var op = m[3];
            if (op === "^") op = "**";
            else if (op === "×") op = "*";
            else if (op === "÷") op = "/";
            else if (op === "(") depth++;
            else if (op === ")" && --depth < 0) return null;
            out.push(op);
        }
    }
    if (out.length === 0)
        return null;
    while (depth-- > 0)
        out.push(")"); // forgive unclosed parens while typing
    return out.join(" ");
}

function format(v) {
    if (typeof v !== "number" || !isFinite(v))
        return null;
    if (Number.isInteger(v) && Math.abs(v) < 1e21)
        return String(v);
    var r = parseFloat(v.toPrecision(12));
    return String(r);
}

// "2^10 + 3" -> "1027"; null when not a valid arithmetic expression
function evaluate(src) {
    var js = compile(src);
    if (js === null)
        return null;
    try {
        var v = (new Function("return (" + js + ");"))();
        return format(v);
    } catch (e) {
        return null;
    }
}
