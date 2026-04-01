import Foundation
import SwiftUI
import AppKit
import MachO

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem!
    var timer: Timer?
    var settingsWindow: NSWindow?
    
    var previousCPUInfo: host_cpu_load_info?
    var previousCPU: Double = 0
    var previousRAM: Double = 0
    var previousDisk: Double = 0
    var diskUpdateCounter = 0
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        startMonitoring()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateUI(cpu: 0, ram: 0, disk: 0)
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let cpu = self.getCPUUsage()
            let ram = self.getMemoryUsage()
            
            self.diskUpdateCounter += 1
            var disk = self.previousDisk
            if self.diskUpdateCounter >= 5 {
                disk = self.getDiskUsage()
                self.previousDisk = disk
                self.diskUpdateCounter = 0
            }
            
            if abs(cpu - self.previousCPU) >= 1 || abs(ram - self.previousRAM) >= 1 || abs(disk - self.previousDisk) >= 1 {
                DispatchQueue.main.async {
                    self.updateUI(cpu: cpu, ram: ram, disk: disk)
                }
                self.previousCPU = cpu
                self.previousRAM = ram
            }
        }
    }
    
    func updateUI(cpu: Double, ram: Double, disk: Double) {
        let view = MenuBarView(cpu: cpu, ram: ram, disk: disk)
        let image = renderViewToImage(view)
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageOnly
    }
    
    // MARK: - CPU Usage
    
    func getCPUUsage() -> Double {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: cpuInfo) / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        if result != KERN_SUCCESS { return 0 }
        
        if let prev = previousCPUInfo {
            let userDiff = Double(cpuInfo.cpu_ticks.0 - prev.cpu_ticks.0)
            let systemDiff = Double(cpuInfo.cpu_ticks.1 - prev.cpu_ticks.1)
            let idleDiff = Double(cpuInfo.cpu_ticks.2 - prev.cpu_ticks.2)
            let niceDiff = Double(cpuInfo.cpu_ticks.3 - prev.cpu_ticks.3)
            let total = userDiff + systemDiff + idleDiff + niceDiff
            let used = userDiff + systemDiff + niceDiff
            previousCPUInfo = cpuInfo
            return (used / total) * 100.0
        } else {
            previousCPUInfo = cpuInfo
            return 0
        }
    }
    
    // MARK: - RAM Usage %
    
    func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: stats) / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        if result != KERN_SUCCESS { return 0 }
        
        var size = mach_msg_type_number_t(MemoryLayout<host_basic_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        var hostInfo = host_basic_info()
        let kr = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &size)
            }
        }
        if kr != KERN_SUCCESS { return 0 }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(stats.active_count) + UInt64(stats.inactive_count) + UInt64(stats.wire_count) + UInt64(stats.speculative_count)
        let used = usedPages * pageSize
        let total = UInt64(hostInfo.max_mem)
        return Double(used) / Double(total) * 100.0
    }
    
    // MARK: - Disk Usage %
    
    func getDiskUsage() -> Double {
        if let home = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let totalSpace = home[.systemSize] as? NSNumber,
           let freeSpace = home[.systemFreeSize] as? NSNumber {
            let used = totalSpace.uint64Value - freeSpace.uint64Value
            return Double(used) / Double(totalSpace.uint64Value) * 100.0
        }
        return 0
    }
}

// MARK: - Render Helper

func renderViewToImage<V: View>(_ view: V) -> NSImage {
    let hostingView = NSHostingView(rootView: view)
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    let fittingSize = hostingView.fittingSize
    hostingView.frame = NSRect(origin: .zero, size: fittingSize)
    
    let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
    
    let image = NSImage(size: hostingView.bounds.size)
    image.addRepresentation(bitmapRep)
    image.isTemplate = false
    return image
}

