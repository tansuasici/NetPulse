import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var monitor: NetworkMonitor!
    var historyStore: HistoryStore!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        historyStore = HistoryStore()
        monitor = NetworkMonitor()
        monitor.start()

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: ContentView(monitor: monitor, historyStore: historyStore)
        )

        // Status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = " ↓0K ↑0K"
            button.action = #selector(togglePopover)
            button.target = self
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

            if let iconPath = Bundle.main.resourcePath.map({ $0 + "/icon.png" }),
               let image = NSImage(contentsOfFile: iconPath) {
                image.size = NSSize(width: 16, height: 16)
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeading
            }
        }

        // Periodic update
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let stats = self.monitor.currentStats
            self.statusItem.button?.title = " " + stats.trayText
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
