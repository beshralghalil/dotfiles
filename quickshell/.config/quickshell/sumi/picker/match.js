.pragma library
.import "../launcher/fuzzy.js" as Fuzzy
// 墨 picker filtering: rofi -dmenu rows ranked with the launcher's fuzzy scorer.
//
// Entries are { text, meta } (display text and hidden search terms). Every
// whitespace-separated query term must match (exact > prefix > word prefix >
// substring > subsequence on the text, then the meta terms); ties keep the
// input order, so recency-ordered lists (cliphist) stay in order. With an
// empty query the input order is kept as-is (rofi -dmenu does not sort).

// pango markup -> plain text (for -markup-rows and -mesg)
function stripMarkup(s) {
    return String(s || "")
        .replace(/<[^>]*>/g, "")
        .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
        .replace(/&quot;/g, "\"").replace(/&apos;/g, "'")
        .replace(/&#(\d+);/g, function (m, n) { return String.fromCodePoint(parseInt(n, 10)); })
        .replace(/&#x([0-9a-fA-F]+);/g, function (m, n) { return String.fromCodePoint(parseInt(n, 16)); })
        .replace(/&amp;/g, "&");
}

// prompt / message / placeholder chrome: drop colour emoji, variation
// selectors and markdown bold so the card stays black and white. Never used
// on the rows themselves (emoji pickers need their emoji).
function monochrome(s) {
    return String(s || "")
        .replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0E}\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}\u{2049}\u{203C}]/gu, "")
        .replace(/\*\*/g, "")
        .replace(/[ \t]+([:,.;!?])/g, "$1")
        .replace(/[ \t]{2,}/g, "  ")
        .replace(/^[\s|:\-–—]+|[\s|:\-–—]+$/g, "")
        .trim();
}

function isImage(path) {
    return /\.(png|jpe?g|webp|gif|bmp|tiff?|avif|jxl|heic|ppm|tga)$/i.test(String(path || ""));
}

function prepare(entries, caseSensitive) {
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        var t = String(e.text || "");
        var m = String(e.meta || "");
        e._name = caseSensitive ? t : t.toLowerCase();
        e._keywords = caseSensitive ? m : m.toLowerCase();
        e._generic = "";
        e._exec = "";
        e._id = "";
    }
    return entries;
}

// returns entry indices, best first; at most `cap` when the query is non-empty
function filter(entries, query, cap, caseSensitive) {
    var q = String(query || "").trim();
    if (!caseSensitive)
        q = q.toLowerCase();
    var out = [];
    var i;
    if (q.length === 0) {
        for (i = 0; i < entries.length; i++)
            out.push(i);
        return out;
    }
    var terms = q.split(/\s+/);
    var scored = [];
    for (i = 0; i < entries.length; i++) {
        var d = entries[i];
        var total = 0;
        for (var t = 0; t < terms.length; t++) {
            var s = Fuzzy._termScore(d, terms[t]);
            if (s <= 0) { total = 0; break; }
            total += s;
        }
        if (total > 0)
            scored.push({ i: i, s: total });
    }
    scored.sort(function (a, b) { return b.s - a.s || a.i - b.i; });
    var n = Math.min(scored.length, cap > 0 ? cap : scored.length);
    for (i = 0; i < n; i++)
        out.push(scored[i].i);
    return out;
}

// "Control+s", "Alt-Delete", "Alt+1,Control+1" -> [{ mods, key }]
// mods is a bitmask of Qt modifiers (Shift 0x02000000, Ctrl 0x04000000,
// Alt 0x08000000, Meta 0x10000000); key is a Qt.Key_* code.
var _named = {
    "delete": 0x01000007, "del": 0x01000007, "return": 0x01000004, "enter": 0x01000005,
    "kp_enter": 0x01000005, "backspace": 0x01000003, "tab": 0x01000001, "iso_left_tab": 0x01000002,
    "escape": 0x01000000, "esc": 0x01000000, "space": 0x20, "insert": 0x01000006,
    "home": 0x01000010, "end": 0x01000011, "left": 0x01000012, "up": 0x01000013,
    "right": 0x01000014, "down": 0x01000015, "page_up": 0x01000016, "prior": 0x01000016,
    "page_down": 0x01000017, "next": 0x01000017, "minus": 0x2d, "plus": 0x2b, "equal": 0x3d,
    "comma": 0x2c, "period": 0x2e, "slash": 0x2f, "backslash": 0x5c, "semicolon": 0x3b,
    "apostrophe": 0x27, "grave": 0x60, "bracketleft": 0x5b, "bracketright": 0x5d,
    "exclam": 0x21, "at": 0x40, "numbersign": 0x23, "dollar": 0x24, "percent": 0x25,
    "asciicircum": 0x5e, "ampersand": 0x26, "asterisk": 0x2a, "parenleft": 0x28, "parenright": 0x29
};
var _mods = {
    "shift": 0x02000000, "control": 0x04000000, "ctrl": 0x04000000, "alt": 0x08000000,
    "mod1": 0x08000000, "super": 0x10000000, "mod4": 0x10000000, "meta": 0x10000000,
    "hyper": 0x10000000
};

function parseKeys(spec) {
    var out = [];
    var parts = String(spec || "").split(",");
    for (var p = 0; p < parts.length; p++) {
        var s = parts[p].trim();
        if (!s.length)
            continue;
        var toks = s.split(/[+-](?=.)/);
        var mods = 0, key = 0, ok = true;
        for (var t = 0; t < toks.length; t++) {
            var tok = toks[t].trim();
            var low = tok.toLowerCase();
            if (t < toks.length - 1) {
                if (_mods[low] === undefined) { ok = false; break; }
                mods |= _mods[low];
            } else if (_named[low] !== undefined) {
                key = _named[low];
            } else if (/^f([1-9]|1[0-9]|2[0-4])$/.test(low)) {
                key = 0x01000030 + parseInt(low.slice(1), 10) - 1;
            } else if (tok.length === 1) {
                key = tok.toUpperCase().charCodeAt(0);
            } else {
                ok = false;
            }
        }
        if (ok && key)
            out.push({ mods: mods, key: key });
    }
    return out;
}

// does a key event (key, modifiers) hit one of the parsed bindings?
function hits(bindings, key, modifiers) {
    var m = modifiers & 0x1e000000;   // shift|ctrl|alt|meta, ignore keypad
    for (var i = 0; i < bindings.length; i++) {
        var b = bindings[i];
        if (b.key === key && b.mods === m)
            return true;
        // "Alt+exclam" style specs vs Shift+1 events, and digits typed with Shift
        if (b.key === key && (b.mods | 0x02000000) === m && key < 0x01000000 && !/[A-Z]/.test(String.fromCharCode(key)))
            return true;
    }
    return false;
}
