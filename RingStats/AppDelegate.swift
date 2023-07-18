import SwiftUI
import LaunchAtLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var ramMenuItem: NSMenuItem!
    var cpuMenuItem: NSMenuItem!

    var timer: Timer?
    
    var statistics: Statistics!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statistics = Statistics()
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        let statusBarMenu = NSMenu()

        let titleFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        let title = NSAttributedString(string: "Ring Stats", attributes: [.font: titleFont])
        statusBarMenu.addItem(withTitle: "", action: nil, keyEquivalent: "").attributedTitle = title
        
        self.ramMenuItem = statusBarMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.cpuMenuItem = statusBarMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")

        statusBarMenu.addItem(NSMenuItem.separator())

        let openAtLoginItem = NSMenuItem(title: "Open at Login", action: #selector(AppDelegate.toggleOpenAtLogin(_:)), keyEquivalent: "")
        openAtLoginItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        statusBarMenu.addItem(openAtLoginItem)

        let openActivityMonitorItem = NSMenuItem(title: "Open Activity Monitor...", action: #selector(AppDelegate.openActivityMonitor(_:)), keyEquivalent: "")
        statusBarMenu.addItem(openActivityMonitorItem)

        statusBarMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusBarMenu.addItem(quitItem)

        statusBarItem.menu = statusBarMenu
        
        updateStats()
        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(AppDelegate.updateStats), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)

        NSApp.activate(ignoringOtherApps: true)
    }

    func drawCircularProgress(innerProgress: CGFloat, innerRadius: Int, outerProgress: CGFloat, outerRadius: Int, color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { rect in
            color.withAlphaComponent(0.2).setStroke()
            
            let innerBackground = NSBezierPath()
            innerBackground.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(innerRadius), startAngle: 0, endAngle: 360)
            innerBackground.lineWidth = 2
            innerBackground.stroke()

            let outerBackground = NSBezierPath()
            outerBackground.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(outerRadius), startAngle: 0, endAngle: 360)
            outerBackground.lineWidth = 2
            outerBackground.stroke()
            
            color.withAlphaComponent(0.9).setStroke()

            let innerPath = NSBezierPath()
            innerPath.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(innerRadius), startAngle: 90, endAngle: 360 + 90 - 360 * innerProgress, clockwise: true)
            innerPath.lineWidth = 2
            innerPath.stroke()
            
            let outerPath = NSBezierPath()
            outerPath.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(outerRadius), startAngle: 90, endAngle: 360 + 90 - 360 * outerProgress, clockwise: true)
            outerPath.lineWidth = 2
            outerPath.stroke()
            return true
        }
        return image
    }
    
    func clamp(value: Double) -> Double {
        return max(0.01, min(0.99, value))
    }

    @objc func updateStats() {
        let memoryPressure = statistics.getMemoryPressure()
        let processorPressure = statistics.getProcessorPressure()
        if memoryPressure.isNaN || processorPressure.isNaN {
            return
        }

        let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        self.ramMenuItem.attributedTitle = NSAttributedString(
            string: String(format: "%2d%% Memory Pressure",Int(memoryPressure * 100)),
            attributes: [.font: font])
        self.ramMenuItem.image = drawCircularProgress(
            innerProgress: clamp(value: memoryPressure), innerRadius: 5,
            outerProgress: 0, outerRadius: 8,
            color: NSColor.black)

        self.cpuMenuItem.attributedTitle = NSAttributedString(
            string: String(format: "%2d%% Processor Load",Int(processorPressure * 100)),
            attributes: [.font: font])
        self.cpuMenuItem.image = drawCircularProgress(
            innerProgress: 0, innerRadius: 5,
            outerProgress: clamp(value: processorPressure), outerRadius: 8,
            color: NSColor.black)

        if let button = self.statusBarItem.button {
            button.image = drawCircularProgress(
                innerProgress: clamp(value: memoryPressure), innerRadius: 5,
                outerProgress: clamp(value: processorPressure), outerRadius: 8,
                color: button.effectiveAppearance.name.rawValue.lowercased().contains("dark") ? NSColor.white : NSColor.black)
            
        }
    }

    @objc func toggleOpenAtLogin(_ sender: AnyObject?) {
        LaunchAtLogin.isEnabled.toggle()

        let item = sender as! NSMenuItem
        item.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    }

    @objc func openActivityMonitor(_ sender: AnyObject?) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Activity Monitor"]
        task.launch()
    }
}

