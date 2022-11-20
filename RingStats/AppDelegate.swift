import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!

    var timer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
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

    func getMemoryPressurePercentage() -> Int {
        let task = Process()
        task.launchPath = "/usr/bin/memory_pressure"
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        let regex = try! NSRegularExpression(pattern: "System-wide memory free percentage: (\\d+)%")
        return 100 - regex.matches(in: output, range: NSRange(location: 0, length: output.utf16.count)).compactMap { match in
            return Int(output[Range(match.range(at: 1), in: output)!])
        }.first!
    }
    
    func getMemoryPressure() -> Double {
        return Double(getMemoryPressurePercentage()) / 100.0
    }
    
    func hostCPULoadInfo() -> host_cpu_load_info? {
        let HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        var cpuLoadInfo = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        if result != KERN_SUCCESS{
            print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
            return nil
        }
        return cpuLoadInfo
    }
    
    var lastUserTicks: natural_t = 0
    var lastSystemTicks: natural_t = 0
    var lastIdleTicks: natural_t = 0
    func getProcessorPressure() -> Double {
        guard let cpuLoadInfo = hostCPULoadInfo() else { return 0.0 }
        let userTicks = cpuLoadInfo.cpu_ticks.0 - lastUserTicks
        let systemTicks = cpuLoadInfo.cpu_ticks.1 - lastSystemTicks
        let idleTicks = cpuLoadInfo.cpu_ticks.2 - lastIdleTicks
        let load = Double(userTicks + systemTicks) / Double(userTicks + systemTicks + idleTicks)
        lastUserTicks = cpuLoadInfo.cpu_ticks.0
        lastSystemTicks = cpuLoadInfo.cpu_ticks.1
        lastIdleTicks = cpuLoadInfo.cpu_ticks.2
        return load
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
            let memoryPressure = getMemoryPressure()
            let processorPressure = getProcessorPressure()
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

