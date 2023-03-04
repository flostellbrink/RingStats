import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!

    var timer: Timer?
    
    var statistics: Statistics!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statistics = Statistics()
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = self.statusBarItem.button {
            button.action = #selector(AppDelegate.openActivityMonitor(_:))
        }
        
        updateStats()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.updateStats()
        })
        
        NSApp.activate(ignoringOtherApps: true)
    }

    
    
    func drawCircularProgress(innerProgress: CGFloat, innerRadius: Int, outerProgress: CGFloat, outerRadius: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { rect in
            NSColor.white.withAlphaComponent(0.2).setStroke()
            
            let innerBackground = NSBezierPath()
            innerBackground.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(innerRadius), startAngle: 0, endAngle: 360)
            innerBackground.lineWidth = 2
            innerBackground.stroke()

            let outerBackground = NSBezierPath()
            outerBackground.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: CGFloat(outerRadius), startAngle: 0, endAngle: 360)
            outerBackground.lineWidth = 2
            outerBackground.stroke()
            
            NSColor.white.setStroke()

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

    func updateStats() {
        if let button = self.statusBarItem.button {
            let memoryPressure = statistics.getMemoryPressure()
            let processorPressure = statistics.getProcessorPressure()
            button.image = drawCircularProgress(
                innerProgress: clamp(value: memoryPressure), innerRadius: 5,
                outerProgress: clamp(value: processorPressure), outerRadius: 8)
        }
    }

    @objc func openActivityMonitor(_ sender: AnyObject?) {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Activity Monitor"]
        task.launch()
    }
}

