pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// 墨 notification daemon (replaces swaync). Two newest-first lists:
//   history  every non-transient notification, kept until dismissed or closed by its sender
//   popups   the toasts on screen, each with its own timer; DND (Config notifDnd) suppresses
//            them unless the sender asks to bypass it (critical, or the SWAYNC_BYPASS_DND hint)
// A notification with a sync tag (x-canonical-private-synchronous / x-dunst-stack-tag, as sent
// by Volume.sh and Brightness.sh) replaces the previous one with the same tag and stays out of
// the history, like an OSD. `int:value` hints become a progress bar on the card.
// Logic adapted from Ryoku's Notifs service (github.com/ryoku-dev/ryoku, GPL-3.0).
Singleton {
    id: root

    readonly property bool dnd: Config.data.notifDnd
    readonly property int popupDuration: Config.data.notifPopupMs > 0 ? Config.data.notifPopupMs : 6000
    readonly property int historyLimit: 100

    property var arrivalMs: ({})
    property var popups: []
    property var popupExpireAt: ({})

    readonly property var tracked: server.trackedNotifications.values
    readonly property var history: {
        const out = root.tracked.filter(n => !n.transient && root.syncTag(n) === "");
        out.sort((a, b) => (root.arrivalMs[b.id] || 0) - (root.arrivalMs[a.id] || 0));
        return out;
    }
    readonly property int count: history.length

    function setDnd(on) { Config.set("notifDnd", on) }
    function toggleDnd() { Config.toggle("notifDnd") }

    function hint(n, key) { return n && n.hints ? n.hints[key] : undefined }
    function syncTag(n) {
        return "" + (hint(n, "x-canonical-private-synchronous") || hint(n, "x-dunst-stack-tag") || hint(n, "synchronous") || "");
    }
    // -1 when the notification carries no progress value
    function progress(n) {
        const v = hint(n, "value");
        return typeof v === "number" ? Math.max(0, Math.min(100, v)) : -1;
    }
    function bypassesDnd(n) {
        return n.urgency === NotificationUrgency.Critical || hint(n, "SWAYNC_BYPASS_DND") === true;
    }
    function isTransient(n) { return n.transient || syncTag(n) !== "" }

    // critical or expire_timeout 0 stays; -1 uses popupDuration; n > 0 uses min(popupDuration, n)
    function popupTtl(n) {
        if (n.urgency === NotificationUrgency.Critical) return -1;
        const et = n.expireTimeout;
        if (et === 0) return -1;
        return et < 0 ? root.popupDuration : Math.min(root.popupDuration, et);
    }

    function timeLabel(n) {
        const ts = n ? root.arrivalMs[n.id] : 0;
        if (!ts) return "";
        const d = new Date(ts);
        return Config.data.clock24h ? Qt.formatTime(d, "HH:mm") : Qt.formatTime(d, "h:mm ap");
    }

    function defaultAction(n) { return (n && n.actions ? n.actions : []).find(a => a.identifier === "default") }
    // click on a card: run the sender's default action (if any), then let it go
    function activate(n) {
        const a = defaultAction(n);
        if (a) a.invoke();
        if (n && n.tracked) n.dismiss();
    }
    function dismiss(n) { if (n && typeof n.dismiss === "function") n.dismiss() }
    function hidePopup(n) {
        removePopup(n);
        if (isTransient(n) && typeof n.expire === "function") n.expire();
    }
    function hideAllPopups() { root.popups.slice().forEach(p => hidePopup(p)) }
    function clearAll() { root.history.slice().forEach(n => n.dismiss()) }

    function addPopup(n) {
        const list = root.popups.filter(p => p.id !== n.id);
        list.unshift(n);
        root.popups = list;
        const ttl = root.popupTtl(n);
        const e = Object.assign({}, root.popupExpireAt);
        if (ttl < 0) delete e[n.id];
        else e[n.id] = Date.now() + ttl;
        root.popupExpireAt = e;
        schedulePopupReap();
    }
    function removePopup(n) {
        root.popups = root.popups.filter(p => p !== n);
        const e = Object.assign({}, root.popupExpireAt);
        delete e[n.id];
        root.popupExpireAt = e;
        schedulePopupReap();
    }

    // drop popups past their deadline; transient ones are released entirely
    Timer {
        id: popupReaper
        onTriggered: {
            const now = Date.now();
            const due = root.popups.filter(p => root.popupExpireAt[p.id] !== undefined && root.popupExpireAt[p.id] <= now);
            due.forEach(p => root.hidePopup(p));
            root.schedulePopupReap();
        }
    }
    function schedulePopupReap() {
        let soonest = -1;
        for (const id in root.popupExpireAt) {
            const t = root.popupExpireAt[id];
            if (soonest < 0 || t < soonest) soonest = t;
        }
        popupReaper.stop();
        if (soonest >= 0) {
            popupReaper.interval = Math.max(1, soonest - Date.now());
            popupReaper.start();
        }
    }

    function trimHistory() {
        const h = root.history;
        for (let i = h.length - 1; i >= root.historyLimit; i--) h[i].expire();
    }

    function hookClosed(n) {
        n.closed.connect(() => {
            root.removePopup(n);
            const a = Object.assign({}, root.arrivalMs);
            delete a[n.id];
            root.arrivalMs = a;
        });
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        Component.onCompleted: {
            const a = Object.assign({}, root.arrivalMs);
            trackedNotifications.values.forEach(n => {
                if (!a[n.id]) a[n.id] = Date.now();
                root.hookClosed(n);
            });
            root.arrivalMs = a;
        }

        onNotification: n => {
            // same sync tag + app: the new one replaces the old one (volume/brightness OSD)
            const tag = root.syncTag(n);
            if (tag !== "")
                root.tracked.slice().filter(o => o !== n && o.appName === n.appName && root.syncTag(o) === tag)
                    .forEach(o => { root.removePopup(o); o.expire(); });

            const a = Object.assign({}, root.arrivalMs);
            a[n.id] = Date.now();
            root.arrivalMs = a;
            n.tracked = true;
            root.hookClosed(n);
            if (!root.dnd || root.bypassesDnd(n)) root.addPopup(n);
            else if (root.isTransient(n)) n.expire();
            root.trimHistory();
        }
    }
}
