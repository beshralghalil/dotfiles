.pragma library
// 墨 launcher ranking. Pure JS (no Qt types) so it can be unit-tested with node
// after stripping the pragma line.
//
// A doc is { id, name, generic, keywords, exec } (all strings, keywords and exec
// already joined by spaces). Every whitespace-separated query term must match
// somewhere; the name counts most (exact > prefix > word prefix > substring >
// subsequence), then generic name / keywords, then the command and desktop id.
// Launch counts add a log-scaled bonus so frequent apps float up without
// burying a precise name match.

function _wordPrefix(hay, term) {
    // term starts a word inside hay (after space, -, _, ., /)
    var i = hay.indexOf(term);
    while (i > 0) {
        var c = hay.charAt(i - 1);
        if (c === " " || c === "-" || c === "_" || c === "." || c === "/")
            return true;
        i = hay.indexOf(term, i + 1);
    }
    return i === 0;
}

// in-order subsequence; returns 0 for no match, else a score that falls with gaps
function _subseq(hay, term) {
    var pos = 0, gaps = 0, last = -1;
    for (var k = 0; k < term.length; k++) {
        var j = hay.indexOf(term.charAt(k), pos);
        if (j < 0)
            return 0;
        if (last >= 0)
            gaps += j - last - 1;
        last = j;
        pos = j + 1;
    }
    return Math.max(1, 120 - gaps * 6);
}

function _termScore(doc, term) {
    var n = doc._name;
    var best = 0;
    if (n === term) best = 1000;
    else if (n.indexOf(term) === 0) best = 800;
    else if (_wordPrefix(n, term)) best = 600;
    else if (n.indexOf(term) > 0) best = 400 - Math.min(100, n.indexOf(term) * 4);
    else if (term.length >= 2) best = _subseq(n, term);

    if (best < 260) {
        if (_wordPrefix(doc._generic, term) || _wordPrefix(doc._keywords, term)) best = Math.max(best, 260);
        else if (doc._generic.indexOf(term) >= 0 || doc._keywords.indexOf(term) >= 0) best = Math.max(best, 160);
    }
    if (best < 200) {
        if (_wordPrefix(doc._exec, term)) best = Math.max(best, 200);
        else if (doc._exec.indexOf(term) >= 0 || doc._id.indexOf(term) >= 0) best = Math.max(best, 100);
    }
    return best;
}

function _prep(doc) {
    if (doc._name === undefined) {
        doc._name = String(doc.name || "").toLowerCase();
        doc._generic = String(doc.generic || "").toLowerCase();
        doc._keywords = String(doc.keywords || "").toLowerCase();
        doc._exec = String(doc.exec || "").toLowerCase();
        doc._id = String(doc.id || "").toLowerCase();
    }
    return doc;
}

function usageBonus(count) {
    return count > 0 ? Math.min(160, Math.round(45 * Math.log(1 + count) / Math.LN2)) : 0;
}

function _byName(a, b) {
    return a._name < b._name ? -1 : a._name > b._name ? 1 : 0;
}

// docs: array of docs; query: string; counts: { id: launches }
// returns a new array of docs, best first
function rank(docs, query, counts) {
    counts = counts || {};
    var q = String(query || "").toLowerCase().trim();
    var out = [];
    var i;
    if (q.length === 0) {
        for (i = 0; i < docs.length; i++)
            out.push({ doc: _prep(docs[i]), score: counts[docs[i].id] || 0 });
    } else {
        var terms = q.split(/\s+/);
        for (i = 0; i < docs.length; i++) {
            var d = _prep(docs[i]);
            var total = 0;
            for (var t = 0; t < terms.length; t++) {
                var s = _termScore(d, terms[t]);
                if (s <= 0) { total = 0; break; }
                total += s;
            }
            if (total > 0)
                out.push({ doc: d, score: total + usageBonus(counts[d.id] || 0) });
        }
    }
    out.sort(function (a, b) { return b.score - a.score || _byName(a.doc, b.doc); });
    var res = [];
    for (i = 0; i < out.length; i++)
        res.push(out[i].doc);
    return res;
}
