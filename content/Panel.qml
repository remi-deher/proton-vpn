pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons
import "../service/Model.js" as Model

// The bar panel. Everything it shows comes from the shared service
// (pluginApi.mainInstance); it holds only view state (folds, filter, drill,
// the profile draft, the split-tunnel app list).
//
// Keyboard: Up/Down walk every row, Enter or Space activates, Left/Right
// change a value, `/` jumps to the country search, `e` edits a profile,
// Escape leaves a field (the bar closes the panel).
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 380
    property bool active: false

    readonly property var vpn: pluginApi ? pluginApi.mainInstance : null
    readonly property real pad: 14 * s

    function tr(text) { return vpn ? vpn.tr(text) : text }

    // view state
    property bool countriesOpen: false
    property string filterQuery: ""
    property string drillCode: ""
    property string drillName: ""
    property var draft: null          // profile being edited, or null
    property bool whereOpen: false
    property string whereQuery: ""
    property bool appsOpen: false
    property string appQuery: ""
    property var appCatalog: []       // [{value,label,description}]
    property bool signOutArmed: false

    implicitWidth: widthBudget
    implicitHeight: Math.min(flick.contentHeight, 640 * s)
    focus: true

    Component.onCompleted: {
        if (vpn) { vpn.refresh(); vpn.loadCities(false) }
        forceActiveFocus()
    }

    // ---- keyboard ----------------------------------------------------------

    Keys.onPressed: function(event) {
        if (event.text === "/" && vpn && vpn.signedIn) {
            countriesOpen = true
            drillCode = ""
            vpn.loadCountries(false)
            Qt.callLater(function() { filterField.forceActiveFocus() })
            event.accepted = true
        }
    }

    function reveal(item) {
        var y = item.mapToItem(flick.contentItem, 0, 0).y
        if (y < flick.contentY)
            flick.contentY = Math.max(0, y - 8 * s)
        else if (y + item.height > flick.contentY + flick.height)
            flick.contentY = y + item.height - flick.height + 8 * s
    }

    // ---- palette for profiles ---------------------------------------------

    // Profile colours follow the active theme: "accent" is the live accent,
    // the others are fixed hues that borrow the accent's saturation and
    // lightness, so they sit in the same family on every scheme.
    readonly property var profileHues: ({ red: 0.0, yellow: 0.12, green: 0.35, cyan: 0.5, blue: 0.6, magenta: 0.82 })
    function profileColor(name) {
        var h = profileHues[String(name)]
        if (h === undefined) return Theme.accent
        var sat = Math.max(0.45, Theme.accent.hslSaturation)
        var lig = Math.min(0.65, Math.max(0.5, Theme.accent.hslLightness))
        return Qt.hsla(h, sat, lig, 1)
    }

    // ---- profile editor ----------------------------------------------------

    function whereOf(args) {
        for (var i = 0; i < args.length; i++) {
            if (args[i] === "--country" && i + 1 < args.length) return "country:" + args[i + 1]
            if (args[i] === "--random") return "random"
            if (args[i].charAt(0) !== "-") return "server:" + args[i]
        }
        return ""
    }

    function featureOf(args) {
        if (args.indexOf("--p2p") !== -1) return "p2p"
        if (args.indexOf("--securecore") !== -1) return "securecore"
        if (args.indexOf("--tor") !== -1) return "tor"
        return ""
    }

    function openEditor(profile) {
        var src = profile ? profile : (vpn.recents.length > 0 ? vpn.recents[0] : null)
        var args = src && Array.isArray(src.args) ? src.args : []
        var where = whereOf(args)
        draft = {
            id: profile ? profile.id : vpn.newProfileId(),
            isNew: !profile,
            name: profile ? profile.name : "",
            color: profile ? profile.color : "accent",
            where: where,
            feature: featureOf(args),
            serverOption: where.indexOf("server:") === 0 && src ? { title: src.title, subtitle: src.subtitle } : null
        }
        whereOpen = false
        whereQuery = ""
        vpn.loadCountries(false)
        Qt.callLater(function() { nameField.forceActiveFocus() })
    }

    function setDraft(key, value) {
        if (draft === null) return
        var d = Object.assign({}, draft)
        d[key] = value
        draft = d
    }

    function closeEditor() {
        draft = null
        whereOpen = false
        root.forceActiveFocus()
    }

    function saveDraft() {
        if (draft === null) return
        var name = String(nameField.text || "").trim()
        if (name === "") { nameField.forceActiveFocus(); return }
        var so = draft.serverOption
        var p = vpn.buildProfile(draft.id, name, draft.color, draft.where, draft.feature,
                                 so ? so.title : "", so ? so.subtitle : "")
        if (!p || !vpn.saveProfile(p)) return
        closeEditor()
    }

    function deleteDraft() {
        if (draft === null || draft.isNew) return
        vpn.deleteProfile(draft.id)
        closeEditor()
    }

    function whereLabel(w) {
        if (w === "") return tr("Fastest")
        if (w === "random") return tr("Random")
        if (w.indexOf("country:") === 0) return vpn.countryName(w.slice(8))
        if (w.indexOf("server:") === 0) return draft && draft.serverOption ? draft.serverOption.title : w.slice(7)
        return w
    }

    readonly property var whereChoices: {
        if (!vpn) return []
        var q = whereQuery.trim().toLowerCase()
        var list = [{ value: "", label: tr("Fastest") }, { value: "random", label: tr("Random") }]
        var cs = vpn.countries
        for (var i = 0; i < cs.length && list.length < 10; i++) {
            if (q === "" || cs[i].name.toLowerCase().indexOf(q) !== -1)
                list.push({ value: "country:" + cs[i].code, label: cs[i].name })
        }
        return list
    }

    readonly property var featureValues: ["", "p2p", "securecore", "tor"]
    function featureLabel(f) {
        return f === "p2p" ? "P2P" : f === "securecore" ? "Secure Core" : f === "tor" ? "Tor" : tr("None")
    }

    // ---- split tunneling apps ---------------------------------------------

    Process {
        id: appsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.appCatalog = JSON.parse(text) } catch (e) { root.appCatalog = [] }
            }
        }
    }

    function openApps() {
        appsOpen = !appsOpen
        if (appsOpen && !appsProc.running) {
            appsProc.command = ["python3", vpn.appsScriptPath]
            appsProc.running = true
        }
    }

    function appLabel(path) {
        for (var i = 0; i < appCatalog.length; i++)
            if (appCatalog[i].value === path) return appCatalog[i].label
        return String(path).split("/").pop()
    }

    readonly property var appMatches: {
        var q = appQuery.trim().toLowerCase()
        var chosen = vpn ? vpn.splitApps : []
        var out = []
        for (var i = 0; i < appCatalog.length && out.length < 8; i++) {
            var a = appCatalog[i]
            if (chosen.indexOf(a.value) !== -1) continue
            if (q === "" || a.label.toLowerCase().indexOf(q) !== -1) out.push(a)
        }
        return out
    }

    function addApp(path) { vpn.setSplitApps(vpn.splitApps.concat([path])) }
    function removeApp(path) { vpn.setSplitApps(vpn.splitApps.filter(function(p) { return p !== path })) }

    // ---- building blocks ---------------------------------------------------

    // Anything the keyboard can land on.
    component Nav: Rectangle {
        id: nav
        signal activate()
        signal edit()
        signal step(int dir)
        activeFocusOnTab: true
        color: "transparent"
        border.width: activeFocus ? 1 : 0
        border.color: Theme.accent
        onActiveFocusChanged: if (activeFocus) root.reveal(nav)
        Keys.onUpPressed: function(e) { var n = nav.nextItemInFocusChain(false); if (n) n.forceActiveFocus(); e.accepted = true }
        Keys.onDownPressed: function(e) { var n = nav.nextItemInFocusChain(true); if (n) n.forceActiveFocus(); e.accepted = true }
        Keys.onLeftPressed: function(e) { nav.step(-1); e.accepted = true }
        Keys.onRightPressed: function(e) { nav.step(1); e.accepted = true }
        Keys.onReturnPressed: function(e) { nav.activate(); e.accepted = true }
        Keys.onEnterPressed: function(e) { nav.activate(); e.accepted = true }
        Keys.onSpacePressed: function(e) { nav.activate(); e.accepted = true }
        Keys.onPressed: function(e) { if (e.key === Qt.Key_E && !e.modifiers) { nav.edit(); e.accepted = true } }
    }

    component Switch: Rectangle {
        id: sw
        property bool on: false
        property bool busy: false
        // pending: a change was accepted and is being applied. The knob moves
        // to `target` at once and pulses until the service confirms.
        property bool pending: false
        property bool target: false
        readonly property bool shown: pending ? target : on
        signal toggled()
        width: 30 * root.s
        height: 14 * root.s
        radius: Theme.radius
        color: shown ? Theme.threadBg : "transparent"
        border.width: 1
        border.color: shown ? Theme.accent : Theme.border
        opacity: busy && !pending ? 0.55 : 1
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Rectangle {
            id: knob
            y: 2 * root.s
            x: sw.shown ? parent.width - width - 2 * root.s : 2 * root.s
            width: 10 * root.s
            height: parent.height - 4 * root.s
            radius: Theme.radius
            color: sw.shown ? Theme.accent : Theme.dim
            Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
            SequentialAnimation on opacity {
                running: sw.pending
                loops: Animation.Infinite
                onRunningChanged: if (!running) knob.opacity = 1
                NumberAnimation { to: 0.3; duration: Motion.pulse }
                NumberAnimation { to: 1.0; duration: Motion.pulse }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !sw.busy && !sw.pending
            onClicked: sw.toggled()
        }
    }

    component Section: Nav {
        id: sec
        property string title: ""
        property bool open: true
        property bool foldable: true
        signal toggled()
        width: parent ? parent.width : 0
        height: 24 * root.s
        activeFocusOnTab: foldable
        onActivate: if (foldable) toggled()
        onStep: function(dir) { if (foldable && (dir > 0) !== open) toggled() }
        MicroLabel {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            label: root.tr(sec.title)
        }
        Text {
            visible: sec.foldable
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: sec.open ? "▾" : "▸"
            color: Theme.dim
            font.pixelSize: 12 * root.s
        }
        MouseArea {
            anchors.fill: parent
            enabled: sec.foldable
            cursorShape: Qt.PointingHandCursor
            onClicked: sec.toggled()
        }
    }

    component Entry: Nav {
        id: ent
        property string title: ""
        property string subtitle: ""
        property string trailing: ""
        property color mark: "transparent"
        property bool current: false
        property bool editable: false
        property bool enabledRow: true
        signal clicked()
        width: parent ? parent.width : 0
        height: (subtitle !== "" ? 40 : 30) * root.s
        opacity: enabledRow ? 1 : 0.45
        activeFocusOnTab: enabledRow
        onActivate: if (enabledRow) clicked()
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: ent.current ? Theme.threadBg : (area.containsMouse && ent.enabledRow ? Theme.sheen : "transparent")
        }
        Rectangle {
            visible: ent.current || ent.mark.a > 0 
            width: 3 * root.s
            height: parent.height
            color: ent.mark.a > 0 ? ent.mark : Theme.accent
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: trail.left
            anchors.leftMargin: 10 * root.s
            anchors.rightMargin: 8 * root.s
            Text {
                width: parent.width
                text: root.tr(ent.title)
                elide: Text.ElideRight
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 13 * root.s
            }
            Text {
                visible: ent.subtitle !== ""
                width: parent.width
                text: root.tr(ent.subtitle)
                elide: Text.ElideRight
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }
        }
        Row {
            id: trail
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * root.s
            Text {
                text: root.tr(ent.trailing)
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11 * root.s
            }
            Text {
                visible: ent.editable
                text: "✎"
                color: editArea.containsMouse ? Theme.accent : Theme.dim
                font.pixelSize: 13 * root.s
                MouseArea {
                    id: editArea
                    anchors.fill: parent
                    anchors.margins: -4 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ent.edit()
                }
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            enabled: ent.enabledRow
            cursorShape: Qt.PointingHandCursor
            onClicked: ent.clicked()
        }
    }

    component Pill: Nav {
        id: pill
        property string label: ""
        property bool quiet: false
        property bool enabledBtn: true
        signal clicked()
        width: pillText.implicitWidth + 22 * root.s
        height: 28 * root.s
        radius: Theme.radius
        activeFocusOnTab: enabledBtn
        onActivate: if (enabledBtn) clicked()
        opacity: enabledBtn ? 1 : 0.5
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: pill.quiet ? (pillArea.containsMouse ? Theme.sheen : "transparent") : (pillArea.pressed ? Theme.vermDeep : Theme.accent)
        }
        Text {
            id: pillText
            anchors.centerIn: parent
            text: root.tr(pill.label)
            color: pill.quiet ? Theme.bright : Theme.cardBot
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: Font.DemiBold
        }
        Rectangle {
            visible: pill.quiet
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.border
        }
        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: pill.enabledBtn
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    component ToggleRow: Nav {
        id: tr
        property string title: ""
        property string subtitle: ""
        property bool on: false
        property bool busy: false
        property bool enabledRow: true
        property string badge: ""
        // Service config key this row waits on ("" = changes apply at once).
        property string pendingKey: ""
        readonly property bool pending: root.vpn && pendingKey !== "" && root.vpn.configPending === pendingKey
        readonly property bool pendingOn: root.vpn ? root.vpn.configPendingValue !== "off" : false
        signal toggled()
        width: parent ? parent.width : 0
        height: (subtitle !== "" || pending ? 42 : 34) * root.s
        opacity: enabledRow ? 1 : 0.45
        radius: Theme.radius
        color: trHover.containsMouse && enabledRow ? Theme.sheen : "transparent"
        border.width: 1
        border.color: activeFocus ? Theme.accent : Theme.border
        activeFocusOnTab: enabledRow && !busy && !pending
        onActivate: if (enabledRow && !busy && !pending) toggled()
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10 * root.s
            anchors.right: badgeText.visible ? badgeText.left : sw.left
            anchors.rightMargin: 10 * root.s
            Text {
                width: parent.width
                text: root.tr(tr.title)
                elide: Text.ElideRight
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 13 * root.s
            }
            Text {
                visible: tr.subtitle !== "" || tr.pending
                width: parent.width
                text: tr.pending ? root.tr(root.vpn.configPendingLabel(tr.pendingKey)) : root.tr(tr.subtitle)
                elide: Text.ElideRight
                color: tr.pending ? Theme.accent : Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.weight: tr.pending ? Font.DemiBold : Font.Normal
            }
        }
        Text {
            id: badgeText
            visible: tr.badge !== ""
            anchors.right: sw.left
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: tr.badge
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10 * root.s
            font.letterSpacing: 1 * root.s
        }
        Switch {
            id: sw
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            on: tr.on
            pending: tr.pending
            target: tr.pendingOn
            busy: tr.busy || !tr.enabledRow
            onToggled: tr.toggled()
        }
        MouseArea {
            id: trHover
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            enabled: tr.enabledRow && !tr.busy && !tr.pending
            cursorShape: Qt.PointingHandCursor
            onClicked: tr.toggled()
        }
        // Indeterminate progress line while a change is being applied.
        Item {
            visible: tr.pending
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            height: 2 * root.s
            clip: true
            Rectangle {
                width: parent.width * 0.3
                height: parent.height
                color: Theme.accent
                SequentialAnimation on x {
                    running: tr.pending
                    loops: Animation.Infinite
                    NumberAnimation { from: -50 * root.s; to: tr.width; duration: Motion.heat; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // A label with a current value that Left/Right (or a click) cycles.
    component CycleRow: Nav {
        id: cyc
        property string title: ""
        property string valueText: ""
        property bool enabledRow: true
        signal cycled(int dir)
        width: parent ? parent.width : 0
        height: 30 * root.s
        opacity: enabledRow ? 1 : 0.45
        activeFocusOnTab: enabledRow
        onActivate: if (enabledRow) cycled(1)
        onStep: function(dir) { if (enabledRow) cycled(dir) }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4 * root.s
            text: root.tr(cyc.title)
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4 * root.s
            text: "‹  " + cyc.valueText + "  ›"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }
        MouseArea {
            anchors.fill: parent
            enabled: cyc.enabledRow
            cursorShape: Qt.PointingHandCursor
            onClicked: cyc.cycled(1)
        }
    }

    component Field: TextField {
        id: fld
        height: 28 * root.s
        color: Theme.bright
        placeholderTextColor: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        selectByMouse: true
        selectionColor: Theme.vermDim
        background: Rectangle {
            radius: Theme.radius
            color: fld.activeFocus ? Theme.sheen : "transparent"
            border.width: 1
            border.color: fld.activeFocus ? Theme.accent : Theme.border
        }
        Keys.onEscapePressed: function(e) { root.forceActiveFocus(); e.accepted = true }
        Keys.onDownPressed: function(e) { var n = fld.nextItemInFocusChain(true); if (n) n.forceActiveFocus(); e.accepted = true }
        Keys.onUpPressed: function(e) { var n = fld.nextItemInFocusChain(false); if (n) n.forceActiveFocus(); e.accepted = true }
        onActiveFocusChanged: if (activeFocus) root.reveal(fld)
    }

    // ---- layout ------------------------------------------------------------

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + root.pad * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: col
            x: root.pad
            y: root.pad
            width: flick.width - root.pad * 2
            spacing: 8 * root.s

            // -- header: mark, status, power switch
            Item {
                width: parent.width
                height: 44 * root.s
                ProtonIcon {
                    id: mark
                    s: root.s
                    iconSize: 26 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.vpn && root.vpn.connected ? Theme.accent : Theme.dim
                }
                Column {
                    anchors.left: mark.right
                    anchors.leftMargin: 12 * root.s
                    anchors.right: power.left
                    anchors.rightMargin: 10 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: root.vpn ? root.tr(root.vpn.displayStatus) : ""
                        color: Theme.bright
                        font.family: Theme.display
                        font.pixelSize: 16 * root.s
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.vpn && root.vpn.connected
                            ? [root.vpn.location, root.vpn.displayServer].filter(function(x) { return x }).join(" · ")
                            : ""
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        elide: Text.ElideRight
                    }
                }
                Switch {
                    id: power
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.vpn && root.vpn.installed && root.vpn.signedIn
                    on: root.vpn ? root.vpn.connected : false
                    busy: root.vpn ? root.vpn.busy : true
                    onToggled: root.vpn.toggle()
                }
            }

            // -- not installed
            Column {
                width: parent.width
                spacing: 8 * root.s
                visible: root.vpn && !root.vpn.installed
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.tr("The Proton VPN command line client isn't installed. Installing it asks for your password through the system prompt.")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
                Pill {
                    label: root.vpn && root.vpn.installing ? "Installing…" : "Install Proton VPN CLI"
                    enabledBtn: root.vpn ? !root.vpn.installing : false
                    onClicked: root.vpn.installCli()
                }
            }

            // -- desktop app conflict
            Text {
                visible: root.vpn && root.vpn.installed && root.vpn.gtkAppInstalled
                width: parent.width
                wrapMode: Text.WordWrap
                text: root.tr("The Proton VPN desktop app is installed. It can't run alongside the CLI: quit it before connecting.")
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }

            // -- signed out
            Column {
                width: parent.width
                spacing: 8 * root.s
                visible: root.vpn && root.vpn.installed && root.vpn.accountProbed && !root.vpn.signedIn
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.tr("Sign in with your Proton account. A terminal opens for your password and 2FA code, then closes.")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
                Row {
                    spacing: 8 * root.s
                    Field {
                        id: userField
                        width: col.width - signBtn.width - 8 * root.s
                        placeholderText: root.tr("Proton username (not your email)")
                        onAccepted: root.vpn.signIn(text)
                    }
                    Pill {
                        id: signBtn
                        label: "Sign in"
                        onClicked: root.vpn.signIn(userField.text)
                    }
                }
            }

            // -- signed in
            Column {
                width: parent.width
                spacing: 8 * root.s
                visible: root.vpn && root.vpn.installed && root.vpn.signedIn

                WorldMap {
                    visible: root.vpn && root.vpn.cities.length > 0
                    s: root.s
                    width: parent.width
                    cities: root.vpn ? root.vpn.cities : []
                    current: root.vpn ? root.vpn.currentPlace : null
                    connected: root.vpn ? root.vpn.connected : false
                    foreground: Theme.bright
                    fontFamily: Theme.font
                    onCityClicked: function(c) {
                        root.drillCode = c.code
                        root.drillName = root.vpn.countryName(c.code)
                        root.countriesOpen = true
                        root.vpn.loadServers(c.code, root.drillName)
                    }
                }

                Text {
                    visible: text !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    text: root.vpn ? root.tr(root.vpn.actionStatus !== "" ? root.vpn.actionStatus : root.vpn.lastError) : ""
                    color: root.vpn && root.vpn.lastError !== "" && root.vpn.actionStatus === "" ? Theme.sun : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }

                // Server, location, then whatever the CLI reports (load, protocol…).
                Column {
                    width: parent.width
                    spacing: 3 * root.s
                    visible: root.vpn && root.vpn.connected
                    Repeater {
                        model: {
                            if (!root.vpn || !root.vpn.connected) return []
                            var rows = [{ label: "Server", value: root.vpn.displayServer }]
                            if (root.vpn.location !== "") rows.push({ label: "Location", value: root.vpn.location })
                            if (root.vpn.forwardedPort !== "") rows.push({ label: "Forwarded port", value: root.vpn.forwardedPort })
                            return rows.concat(root.vpn.fields)
                        }
                        delegate: Item {
                            required property var modelData
                            width: parent ? parent.width : 0
                            height: 18 * root.s
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.tr(parent.modelData.label)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                width: parent.width * 0.65
                                horizontalAlignment: Text.AlignRight
                                text: parent.modelData.value
                                elide: Text.ElideRight
                                color: Theme.bright
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                            }
                        }
                    }
                }

                Traffic {
                    visible: root.vpn && root.vpn.connected && root.vpn.linkActive && !root.vpn.busy && root.vpn.rxHistory.length > 0
                    s: root.s
                    width: parent.width
                    rxHistory: root.vpn ? root.vpn.rxHistory : []
                    txHistory: root.vpn ? root.vpn.txHistory : []
                    rxRate: root.vpn ? root.vpn.rxRate : 0
                    txRate: root.vpn ? root.vpn.txRate : 0
                    sessionRx: root.vpn ? root.vpn.sessionRx : 0
                    sessionTx: root.vpn ? root.vpn.sessionTx : 0
                    uptimeSec: root.vpn ? root.vpn.uptimeSec : 0
                    foreground: Theme.bright
                    fontFamily: Theme.font
                }

                // -- quick connect
                Section {
                    title: "Quick connect"
                    open: root.vpn ? root.vpn.quickExpanded : true
                    onToggled: root.vpn.setQuickExpanded(!root.vpn.quickExpanded)
                }
                Column {
                    width: parent.width
                    visible: root.vpn && root.vpn.quickExpanded
                    Entry {
                        title: "Fastest"; subtitle: "Proton's best pick for your location"
                        enabledRow: root.vpn ? !root.vpn.busy : false
                        onClicked: root.vpn.connectFastest()
                    }
                    Entry {
                        title: "Random"; subtitle: "Any available server"
                        trailing: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                        enabledRow: root.vpn ? !root.vpn.busy && !root.vpn.freePlan : false
                        onClicked: root.vpn.connectRandom()
                    }
                    Entry {
                        title: "P2P"; subtitle: "Fastest server that allows file sharing"
                        trailing: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                        enabledRow: root.vpn ? !root.vpn.busy && !root.vpn.freePlan : false
                        onClicked: root.vpn.connectP2P()
                    }
                    Entry {
                        title: "Secure Core"; subtitle: "Two hops through Switzerland, Iceland or Sweden"
                        trailing: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                        enabledRow: root.vpn ? !root.vpn.busy && !root.vpn.freePlan : false
                        onClicked: root.vpn.connectSecureCore()
                    }
                    Entry {
                        title: "Tor"; subtitle: "VPN first, then the Tor network"
                        trailing: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                        enabledRow: root.vpn ? !root.vpn.busy && !root.vpn.freePlan : false
                        onClicked: root.vpn.connectTor()
                    }
                }

                // -- profiles
                Section {
                    title: root.draft === null ? "Profiles" : (root.draft.isNew ? "New profile" : "Edit profile")
                    foldable: root.draft === null
                    open: root.vpn ? root.vpn.profilesExpanded : true
                    onToggled: root.vpn.setProfilesExpanded(!root.vpn.profilesExpanded)
                }
                Column {
                    width: parent.width
                    visible: root.draft === null && root.vpn && root.vpn.profilesExpanded
                    Repeater {
                        model: root.vpn ? root.vpn.profiles : []
                        delegate: Entry {
                            required property var modelData
                            title: modelData.name
                            subtitle: modelData.title + (modelData.subtitle !== "" ? " · " + modelData.subtitle : "")
                            mark: root.profileColor(modelData.color)
                            editable: true
                            trailing: root.vpn.connected && root.vpn.activeProfile === modelData.id ? "●" : ""
                            enabledRow: root.vpn ? !root.vpn.busy : false
                            onClicked: root.vpn.connectProfile(modelData.id)
                            onEdit: root.openEditor(modelData)
                        }
                    }
                    Entry {
                        title: "New profile"
                        subtitle: root.vpn && root.vpn.profiles.length === 0 ? "Name a place, pick a colour, get there in one click" : ""
                        trailing: "+"
                        onClicked: root.openEditor(null)
                    }
                }

                // profile editor
                Column {
                    id: editor
                    width: parent.width
                    spacing: 6 * root.s
                    visible: root.draft !== null

                    Field {
                        id: nameField
                        width: parent.width
                        placeholderText: root.tr("Name, like Home or Work")
                        maximumLength: root.vpn ? root.vpn.profileNameMax : 32
                        text: root.draft ? root.draft.name : ""
                        onAccepted: root.saveDraft()
                    }

                    // colour swatches
                    Nav {
                        id: swatchRow
                        width: parent.width
                        height: 30 * root.s
                        onStep: function(dir) {
                            var names = root.vpn.profileColors
                            var i = Math.max(0, names.indexOf(root.draft.color))
                            root.setDraft("color", names[(i + dir + names.length) % names.length])
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 4 * root.s
                            text: root.tr("Colour")
                            color: Theme.bright
                            font.family: Theme.font
                            font.pixelSize: 13 * root.s
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 4 * root.s
                            spacing: 6 * root.s
                            Repeater {
                                model: root.vpn ? root.vpn.profileColors : []
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 16 * root.s
                                    height: width
                                    radius: width / 2
                                    color: root.profileColor(modelData)
                                    border.width: root.draft && root.draft.color === modelData ? 2 : 0
                                    border.color: Theme.bright
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setDraft("color", parent.modelData)
                                    }
                                }
                            }
                        }
                    }

                    // where
                    CycleRow {
                        title: "Where"
                        valueText: root.draft ? root.whereLabel(root.draft.where) : ""
                        onActivate: { root.whereOpen = !root.whereOpen; root.whereQuery = "" }
                        onStep: function(dir) { root.whereOpen = true }
                        onCycled: function(dir) { root.whereOpen = !root.whereOpen }
                    }
                    Column {
                        width: parent.width
                        visible: root.whereOpen
                        spacing: 2 * root.s
                        Field {
                            width: parent.width
                            placeholderText: root.tr("Find a country")
                            onTextChanged: root.whereQuery = text
                        }
                        Repeater {
                            model: root.whereChoices
                            delegate: Entry {
                                required property var modelData
                                title: modelData.label
                                current: root.draft && root.draft.where === modelData.value
                                onClicked: { root.setDraft("where", modelData.value); root.whereOpen = false }
                            }
                        }
                    }

                    // feature (a named server or Random ignores flags)
                    CycleRow {
                        title: "Feature"
                        valueText: root.draft ? root.featureLabel(root.draft.feature) : ""
                        enabledRow: root.draft !== null && root.draft.where.indexOf("server:") !== 0 && root.draft.where !== "random"
                        onCycled: function(dir) {
                            var i = Math.max(0, root.featureValues.indexOf(root.draft.feature))
                            var n = root.featureValues.length
                            root.setDraft("feature", root.featureValues[(i + dir + n) % n])
                        }
                    }

                    Row {
                        spacing: 8 * root.s
                        Pill { label: "Save"; onClicked: root.saveDraft() }
                        Pill { label: "Cancel"; quiet: true; onClicked: root.closeEditor() }
                        Pill {
                            visible: root.draft !== null && !root.draft.isNew
                            label: "Delete"
                            quiet: true
                            onClicked: root.deleteDraft()
                        }
                    }
                }

                // -- recent
                Section {
                    visible: root.vpn && root.vpn.recents.length > 0
                    title: "Recent"
                    open: root.vpn ? root.vpn.recentsExpanded : true
                    onToggled: root.vpn.setRecentsExpanded(!root.vpn.recentsExpanded)
                }
                Column {
                    width: parent.width
                    visible: root.vpn && root.vpn.recents.length > 0 && root.vpn.recentsExpanded
                    Repeater {
                        model: root.vpn ? root.vpn.recents : []
                        delegate: Entry {
                            required property var modelData
                            required property int index
                            title: modelData.title
                            subtitle: modelData.subtitle
                            enabledRow: root.vpn ? !root.vpn.busy : false
                            onClicked: root.vpn.connectRecent(index)
                        }
                    }
                }

                // -- countries and cities
                Section {
                    title: root.drillCode !== "" ? ("Cities · " + root.drillName) : "Countries"
                    open: root.countriesOpen
                    onToggled: {
                        root.countriesOpen = !root.countriesOpen
                        if (root.countriesOpen && root.vpn) root.vpn.loadCountries(false)
                    }
                }
                Column {
                    width: parent.width
                    spacing: 4 * root.s
                    visible: root.countriesOpen

                    Column {
                        width: parent.width
                        visible: root.drillCode === ""
                        spacing: 4 * root.s
                        Field {
                            id: filterField
                            width: parent.width
                            placeholderText: root.tr("Find a country")
                            onTextChanged: root.filterQuery = text
                        }
                        Repeater {
                            model: root.vpn ? Model.filterCountries(root.vpn.countries, root.filterQuery) : []
                            delegate: Entry {
                                required property var modelData
                                title: modelData.name
                                trailing: modelData.code + "  ›"
                                onClicked: {
                                    root.drillCode = modelData.code
                                    root.drillName = modelData.name
                                    root.vpn.loadServers(modelData.code, modelData.name)
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        visible: root.drillCode !== ""
                        Entry {
                            title: "‹  " + root.tr("All countries")
                            onClicked: { root.drillCode = ""; root.vpn.clearServers() }
                        }
                        Entry {
                            title: "Fastest in " + root.drillName
                            enabledRow: root.vpn ? !root.vpn.busy : false
                            onClicked: root.vpn.connectCountry(root.drillCode, root.drillName)
                        }
                        Text {
                            visible: root.vpn && root.vpn.serversLoading
                            text: root.tr("Loading…")
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                        }
                        Repeater {
                            model: root.vpn ? root.vpn.servers : []
                            delegate: Entry {
                                required property var modelData
                                title: modelData.city
                                subtitle: modelData.count > 1 ? (modelData.count + " servers") : modelData.name
                                trailing: modelData.load !== undefined && modelData.load !== null ? (modelData.load + "%") : ""
                                enabledRow: root.vpn ? !root.vpn.busy : false
                                onClicked: root.vpn.connectServer(modelData.name, modelData.city, root.drillName)
                            }
                        }
                    }
                }

                // -- protection
                Section { title: "Protection"; foldable: false }
                ToggleRow {
                    title: "Kill Switch"
                    pendingKey: "kill-switch"
                    subtitle: "Block traffic if the tunnel drops"
                    on: root.vpn ? root.vpn.killSwitchOn : false
                    busy: root.vpn ? !root.vpn.configLoaded : true
                    enabledRow: root.vpn ? !root.vpn.splitActive : false
                    onToggled: root.vpn.toggleKillSwitch()
                }
                ToggleRow {
                    title: "NetShield"
                    pendingKey: "netshield"
                    badge: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                    subtitle: "Block malware, ads and trackers"
                    on: root.vpn ? root.vpn.netShieldOn : false
                    busy: root.vpn ? !root.vpn.configLoaded : true
                    enabledRow: root.vpn ? !root.vpn.freePlan : false
                    onToggled: root.vpn.toggleNetShield()
                }
                ToggleRow {
                    title: "Port forwarding"
                    pendingKey: "port-forwarding"
                    badge: root.vpn && root.vpn.freePlan ? "PLUS" : ""
                    subtitle: root.vpn && root.vpn.forwardedPort !== "" ? ("Forwarded port " + root.vpn.forwardedPort) : "Open an inbound port"
                    on: root.vpn ? root.vpn.portForwardingOn : false
                    busy: root.vpn ? !root.vpn.configLoaded : true
                    enabledRow: root.vpn ? !root.vpn.freePlan : false
                    onToggled: root.vpn.togglePortForwarding()
                }
                ToggleRow {
                    title: "Always On"
                    subtitle: "Reconnect automatically"
                    on: root.vpn ? root.vpn.autoConnect : false
                    onToggled: root.vpn.toggleAutoConnect()
                }

                // -- split tunneling. Proton ignores it while the Kill Switch
                // is on, so the row says that instead of offering a dead switch.
                ToggleRow {
                    title: "Split tunneling"
                    subtitle: root.vpn ? root.vpn.splitDescription() : ""
                    on: root.vpn ? root.vpn.splitActive : false
                    enabledRow: root.vpn ? (root.vpn.splitAvailable && !root.vpn.splitBlocked) : false
                    onToggled: root.vpn.toggleSplitTunnel()
                }
                Column {
                    width: parent.width
                    spacing: 4 * root.s
                    visible: root.vpn && root.vpn.splitActive

                    CycleRow {
                        title: "Mode"
                        valueText: root.vpn ? (root.vpn.splitMode === "include"
                            ? root.tr("Include: only chosen apps use the VPN")
                            : root.tr("Exclude: chosen apps skip the VPN")) : ""
                        onCycled: function(dir) { root.vpn.setSplitMode(root.vpn.splitMode === "include" ? "exclude" : "include") }
                    }

                    Entry {
                        title: "Apps"
                        subtitle: root.vpn && root.vpn.splitApps.length > 0
                            ? root.vpn.splitApps.map(function(p) { return root.appLabel(p) }).join(", ")
                            : "None chosen"
                        trailing: root.appsOpen ? "▾" : "▸"
                        onClicked: root.openApps()
                    }

                    Column {
                        width: parent.width
                        visible: root.appsOpen
                        spacing: 2 * root.s

                        Repeater {
                            model: root.vpn ? root.vpn.splitApps : []
                            delegate: Entry {
                                required property var modelData
                                title: root.appLabel(modelData)
                                subtitle: modelData
                                trailing: "✕"
                                current: true
                                onClicked: root.removeApp(modelData)
                            }
                        }
                        Field {
                            width: parent.width
                            placeholderText: root.tr("Search apps…")
                            onTextChanged: root.appQuery = text
                        }
                        Text {
                            visible: root.appMatches.length === 0
                            text: root.tr("No apps found")
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                        }
                        Repeater {
                            model: root.appMatches
                            delegate: Entry {
                                required property var modelData
                                title: modelData.label
                                subtitle: modelData.description
                                trailing: "+"
                                onClicked: root.addApp(modelData.value)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.tr("Restart each chosen app after connecting, or it keeps using the tunnel it started on.")
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }
                }

                // -- account
                Section { title: "Account"; foldable: false }
                Item {
                    width: parent.width
                    height: 30 * root.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 4 * root.s
                        anchors.right: signOutBtn.left
                        anchors.rightMargin: 8 * root.s
                        elide: Text.ElideRight
                        text: root.vpn ? [root.vpn.account, root.vpn.plan].filter(function(x) { return x }).join(" · ") : ""
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                    }
                    Pill {
                        id: signOutBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Sign out"
                        quiet: true
                        enabledBtn: root.vpn ? !root.vpn.busy : false
                        onClicked: root.vpn.signOut()
                    }
                }
            }
        }
    }
}
