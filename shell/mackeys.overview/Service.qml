import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Mission Control-like overview of the focused monitor's workspaces.
// Click a window to focus it, a card to switch to that workspace, empty space
// or Esc to close. Driven from Hyprland (four-finger swipe up) over IPC:
//   omarchy-shell macOverview toggle | open | close
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property bool shown: false        // drives the fade/scale animation
  property var cards: []            // [{ id, name, isNew, active, windows: [...] }]
  property real monX: 0
  property real monY: 0
  property real monW: 1920
  property real monH: 1080

  readonly property int margin: Style.space(48)
  readonly property int gap: Style.space(28)
  readonly property int labelHeight: Style.font.subtitle + Style.spacing.lg

  function norm(address) {
    return String(address || "").trim().toLowerCase().replace(/^0x/, "")
  }

  function iconFor(cls) {
    var name = String(cls || "")
    var entry = null
    try {
      entry = DesktopEntries.heuristicLookup(name)
    } catch (e) {
      entry = null
    }
    var icon = entry && entry.icon ? entry.icon : name
    var lib = root.shell && root.shell.appLibrary
    if (lib && typeof lib.iconSource === "function") return lib.iconSource(icon)
    return Quickshell.iconPath(icon, true)
  }

  function build() {
    var mon = Hyprland.focusedMonitor
    var monName = mon ? mon.name : ""
    if (mon) {
      var mo = mon.lastIpcObject || {}
      monX = mo.x || 0
      monY = mo.y || 0
      monW = (mo.width || 1920) / (mo.scale || 1)
      monH = (mo.height || 1080) / (mo.scale || 1)
    }
    var activeId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    var byWs = {}
    var names = {}
    var wss = Hyprland.workspaces.values
    for (var w = 0; w < wss.length; w++) {
      var ws = wss[w]
      if (ws.id < 1) continue
      var wo = ws.lastIpcObject || {}
      if (monName && wo.monitor && wo.monitor !== monName) continue
      byWs[ws.id] = []
      names[ws.id] = ws.name || String(ws.id)
    }
    if (!byWs[activeId]) byWs[activeId] = []

    var tops = Hyprland.toplevels.values
    for (var i = 0; i < tops.length; i++) {
      var t = tops[i]
      var o = t.lastIpcObject
      if (!o || !o.workspace || o.workspace.id < 1 || o.hidden) continue
      if (!byWs[o.workspace.id]) continue
      var cls = String(o["class"] || o.initialClass || "")
      byWs[o.workspace.id].push({
        top: t,
        address: norm(o.address || t.address),
        cls: cls,
        title: String(t.title || o.title || cls),
        icon: iconFor(cls),
        x: (o.at ? o.at[0] : 0) - monX,
        y: (o.at ? o.at[1] : 0) - monY,
        w: o.size ? o.size[0] : 100,
        h: o.size ? o.size[1] : 100,
        floating: !!o.floating,
      })
    }

    var ids = Object.keys(byWs).map(Number).sort(function(a, b) { return a - b })
    var out = ids.map(function(id) {
      var wins = byWs[id]
      // Floating windows paint above tiled ones.
      wins.sort(function(a, b) { return (a.floating ? 1 : 0) - (b.floating ? 1 : 0) })
      return { id: id, name: names[id] || String(id), isNew: false, active: id === activeId, windows: wins }
    })
    var nextId = ids.length ? ids[ids.length - 1] + 1 : 1
    out.push({ id: nextId, name: "+", isNew: true, active: false, windows: [] })
    cards = out
  }

  function open() {
    if (opened) return
    Hyprland.refreshToplevels()
    Hyprland.refreshWorkspaces()
    Hyprland.refreshMonitors()
    openDelay.restart()
  }

  function close() {
    if (!opened) return
    shown = false
    closeDelay.restart()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function goWorkspace(id) {
    Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
    close()
  }

  function goWindow(address) {
    Hyprland.dispatch('hl.dsp.focus({ window = "address:0x' + norm(address) + '" })')
    close()
  }

  Timer {
    id: openDelay
    interval: 60
    onTriggered: {
      root.build()
      root.opened = true
      root.shown = true
      Qt.callLater(function() { keys.forceActiveFocus() })
    }
  }

  Timer {
    id: closeDelay
    interval: 160
    onTriggered: root.opened = false
  }

  IpcHandler {
    target: "macOverview"
    function toggle(): void { root.toggle() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    // Read-only snapshot for scripts and tests (builds without opening).
    function state(): string {
      root.build()
      return JSON.stringify({ opened: root.opened, monitor: [root.monW, root.monH], cards: root.cards.map(function(c) {
        return { id: c.id, active: c.active, isNew: c.isNew, windows: c.windows.map(function(w) {
          return { address: w.address, cls: w.cls, x: w.x, y: w.y, w: w.w, h: w.h, hasWayland: !!(w.top && w.top.wayland) } }) } }) })
    }
  }

  PanelWindow {
    id: win
    screen: Quickshell.screens.find(function(s) {
      return Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name
    }) || Quickshell.screens[0]
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "mackeys-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.close()

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.72)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }

      Item {
        id: stage
        anchors.fill: parent
        anchors.margins: root.margin
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 1.06
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        readonly property int count: Math.max(1, root.cards.length)
        readonly property int cols: Math.max(1, Math.min(count, Math.ceil(Math.sqrt(count * (width / Math.max(1, height)) * (root.monH / root.monW)))))
        readonly property int rows: Math.ceil(count / cols)
        readonly property real cardW: Math.min(
          (width - root.gap * (cols - 1)) / cols,
          ((height - root.gap * (rows - 1)) / rows - root.labelHeight) * root.monW / root.monH)
        readonly property real cardH: cardW * root.monH / root.monW

        Grid {
          anchors.centerIn: parent
          columns: stage.cols
          spacing: root.gap

          Repeater {
            model: root.cards
            delegate: Item {
              id: card
              required property var modelData
              width: stage.cardW
              height: stage.cardH + root.labelHeight
              readonly property real k: stage.cardW / root.monW

              Rectangle {
                id: frame
                width: parent.width
                height: stage.cardH
                radius: Math.max(Style.cornerRadius, Style.space(10))
                clip: true
                color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.85)
                border.width: card.modelData.active || cardMouse.containsMouse ? Math.max(2, Style.space(2)) : 1
                border.color: card.modelData.active || cardMouse.containsMouse
                  ? Color.accent
                  : Qt.rgba(Color.popups.border.r, Color.popups.border.g, Color.popups.border.b, 0.35)

                MouseArea {
                  id: cardMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: root.goWorkspace(card.modelData.id)
                }

                Text {
                  anchors.centerIn: parent
                  visible: card.modelData.isNew
                  text: "+"
                  color: Color.popups.text
                  opacity: 0.6
                  font.family: Style.font.family
                  font.pixelSize: stage.cardH * 0.3
                }

                Repeater {
                  model: card.modelData.windows
                  delegate: Rectangle {
                    id: winTile
                    required property var modelData
                    x: Math.max(0, modelData.x * card.k)
                    y: Math.max(0, modelData.y * card.k)
                    width: Math.max(8, modelData.w * card.k)
                    height: Math.max(8, modelData.h * card.k)
                    radius: Math.max(2, Style.cornerRadius * card.k)
                    clip: true
                    color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.9)
                    border.width: winMouse.containsMouse ? Math.max(2, Style.space(2)) : 1
                    border.color: winMouse.containsMouse
                      ? Color.accent
                      : Qt.rgba(Color.popups.border.r, Color.popups.border.g, Color.popups.border.b, 0.5)

                    ScreencopyView {
                      id: shot
                      anchors.fill: parent
                      anchors.margins: 1
                      captureSource: winTile.modelData.top && winTile.modelData.top.wayland ? winTile.modelData.top.wayland : null
                      live: false
                    }

                    Image {
                      anchors.centerIn: parent
                      readonly property int size: Math.min(parent.width, parent.height) * 0.42
                      width: size
                      height: size
                      sourceSize.width: size * 2
                      sourceSize.height: size * 2
                      source: winTile.modelData.icon || ""
                      fillMode: Image.PreserveAspectFit
                      asynchronous: true
                      visible: !shot.hasContent && status === Image.Ready
                    }

                    MouseArea {
                      id: winMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: root.goWindow(winTile.modelData.address)
                    }
                  }
                }
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: stage.cardH + Style.spacing.sm
                text: card.modelData.isNew ? "New workspace" : "Workspace " + card.modelData.name
                color: Color.popups.text
                opacity: card.modelData.active ? 1 : 0.75
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: card.modelData.active
              }
            }
          }
        }
      }
    }
  }
}
