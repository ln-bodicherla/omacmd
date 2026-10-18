import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Mac-style ⌘Tab strip. Hyprland owns the keys (hold ⌘, tap Tab, let go) and
// drives this over IPC, so the surface never takes keyboard focus:
//   omarchy-shell omacmdSwitcher show "0xaaab…,0xaaac…" 1
//   omarchy-shell omacmdSwitcher hide
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property var entries: []          // [{ address, cls, title, icon }]
  property int selected: 0

  readonly property int tileSize: Math.max(64, Style.font.display * 3)
  readonly property int iconSize: Math.round(tileSize * 0.72)
  readonly property int pad: Style.spacing.huge

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

  function lookup(address) {
    var want = norm(address)
    var tops = Hyprland.toplevels.values
    for (var i = 0; i < tops.length; i++) {
      var t = tops[i]
      var o = t.lastIpcObject || {}
      if (norm(t.address) === want || norm(o.address) === want) {
        var cls = String(o["class"] || o.initialClass || (t.wayland ? t.wayland.appId : "") || "")
        return { address: want, cls: cls, title: String(t.title || o.title || cls), icon: iconFor(cls) }
      }
    }
    return null
  }

  function show(addresses, index) {
    var list = String(addresses || "").split(",")
    var out = []
    for (var i = 0; i < list.length; i++) {
      if (!norm(list[i])) continue
      var e = lookup(list[i])
      // Unknown to Quickshell yet (just opened): keep the slot so indexes line up.
      out.push(e || { address: norm(list[i]), cls: "", title: "", icon: "" })
    }
    if (out.length < 2) {
      hide()
      return
    }
    var same = out.length === entries.length
    for (var j = 0; same && j < out.length; j++) same = out[j].address === entries[j].address
    if (!same) entries = out
    selected = Math.max(0, Math.min(out.length - 1, Number(index) || 0))
    opened = true
  }

  function hide() {
    opened = false
  }

  IpcHandler {
    target: "omacmdSwitcher"
    function show(addresses: string, index: int): void { root.show(addresses, index) }
    function hide(): void { root.hide() }
    // Read-only snapshot for scripts and tests.
    function state(): string {
      return JSON.stringify({ opened: root.opened, selected: root.selected, entries: root.entries })
    }
  }

  PanelWindow {
    id: win
    screen: Quickshell.screens.find(function(s) {
      return Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name
    }) || Quickshell.screens[0]
    visible: root.opened
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omacmd-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    implicitWidth: panel.width
    implicitHeight: panel.height
    // Input passes straight through; this is display only.
    mask: Region {}

    Rectangle {
      id: panel
      width: row.width + root.pad * 2
      height: root.tileSize + titleText.height + root.pad * 2 + Style.spacing.md
      radius: Math.max(Style.cornerRadius, Style.space(18))
      color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.82)
      border.width: Math.max(1, Style.normalBorderWidth)
      border.color: Qt.rgba(Color.popups.border.r, Color.popups.border.g, Color.popups.border.b, 0.45)

      Row {
        id: row
        x: root.pad
        y: root.pad
        spacing: Style.spacing.md

        Repeater {
          model: root.entries
          delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool isSelected: index === root.selected
            width: root.tileSize
            height: root.tileSize
            radius: Math.max(Style.cornerRadius, Style.space(12))
            color: isSelected
              ? Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.16)
              : "transparent"

            Image {
              id: icon
              anchors.centerIn: parent
              width: root.iconSize
              height: root.iconSize
              sourceSize.width: root.iconSize * 2
              sourceSize.height: root.iconSize * 2
              source: modelData.icon || ""
              fillMode: Image.PreserveAspectFit
              smooth: true
              asynchronous: true
              visible: status === Image.Ready
            }

            // Letter tile when no icon resolves.
            Rectangle {
              anchors.centerIn: parent
              width: root.iconSize
              height: root.iconSize
              radius: width * 0.22
              visible: icon.status !== Image.Ready
              color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35)
              Text {
                anchors.centerIn: parent
                text: (modelData.cls || modelData.title || "?").replace(/^.*\./, "").charAt(0).toUpperCase()
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: root.iconSize * 0.5
                font.bold: true
              }
            }
          }
        }
      }

      Text {
        id: titleText
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad + root.tileSize + Style.spacing.md
        width: Math.max(root.tileSize, panel.width - root.pad * 2)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: {
          var e = root.entries[root.selected]
          return e ? (e.title || e.cls) : ""
        }
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.subtitle
      }
    }
  }
}
