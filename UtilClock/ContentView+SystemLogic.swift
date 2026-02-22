import SwiftUI
#if os(macOS)
import AppKit
import CoreAudio
import Darwin
#endif

extension ContentView {
    func refreshAudioDeviceName() {
        selectedAudioDeviceName = currentDefaultOutputDeviceName() ?? L10n.noAudioDevice
    }

    func currentDefaultOutputDeviceName() -> String? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusDevice = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard statusDevice == noErr, deviceID != 0 else { return nil }

        var deviceNameRef: Unmanaged<CFString>?
        size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let statusName = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &deviceNameRef
        )
        guard statusName == noErr else { return nil }
        return deviceNameRef?.takeUnretainedValue() as String?
    }

    func refreshCPUUsage() {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &loadInfo) { loadInfoPtr in
            loadInfoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let current = (
            user: loadInfo.cpu_ticks.0,
            system: loadInfo.cpu_ticks.1,
            idle: loadInfo.cpu_ticks.2,
            nice: loadInfo.cpu_ticks.3
        )

        guard let previous = lastCPUTicks else {
            lastCPUTicks = current
            return
        }

        let userDiff = Double(current.user &- previous.user)
        let systemDiff = Double(current.system &- previous.system)
        let idleDiff = Double(current.idle &- previous.idle)
        let niceDiff = Double(current.nice &- previous.nice)
        let total = userDiff + systemDiff + idleDiff + niceDiff

        if total > 0 {
            let active = userDiff + systemDiff + niceDiff
            cpuUsagePercent = max(0, min(100, (active / total) * 100))
        }

        lastCPUTicks = current
        refreshMemoryUsage()
    }

    func refreshRunningAppsUsage() {
        let cpuByPID = cpuUsageByPID()
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.isTerminated == false &&
                app.activationPolicy == .regular &&
                app.bundleURL != nil &&
                app.bundleIdentifier != nil
            }
            .map { app -> RunningAppUsage in
                let pid = app.processIdentifier
                let appName = app.localizedName ?? app.bundleURL?.deletingPathExtension().lastPathComponent ?? "app"
                let icon = app.icon ?? NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
                icon.size = NSSize(width: 32, height: 32)
                return RunningAppUsage(
                    id: pid,
                    name: appName,
                    cpuPercent: max(0, cpuByPID[pid] ?? 0),
                    icon: icon
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.cpuPercent - rhs.cpuPercent) > 0.001 {
                    return lhs.cpuPercent > rhs.cpuPercent
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

        runningAppsUsage = Array(runningApps.prefix(12))
    }

    func refreshRunningProcessesUsage() {
        let processes = cpuAndCommandByPID()
            .map { pid, data in
                RunningProcessUsage(
                    id: pid,
                    name: data.command,
                    cpuPercent: data.cpuPercent
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.cpuPercent - rhs.cpuPercent) > 0.001 {
                    return lhs.cpuPercent > rhs.cpuPercent
                }
                return lhs.id < rhs.id
            }

        runningProcessesUsage = Array(processes.prefix(20))
    }

    func refreshAppsMonitorData() {
        if selectedAppsMonitorMode == .apps {
            refreshRunningAppsUsage()
        } else {
            refreshRunningProcessesUsage()
        }
    }

    func refreshNetworkModeData(forcePublicIPRefresh: Bool) {
        refreshPrimaryNetworkInterfacesIfNeeded(force: false)
        refreshPrivateIPAddress()
        refreshNetworkThroughput()
        refreshPublicIPAddressIfNeeded(force: forcePublicIPRefresh)
    }

    func refreshPrimaryNetworkInterfacesIfNeeded(force: Bool) {
        let now = Date()
        if force == false,
           let last = networkLastInterfaceRefresh,
           now.timeIntervalSince(last) < 6 {
            return
        }

        let counters = networkInterfaceByteCounters()
        let primary = primaryInterfacesFromNetworkSetup()

        if let wifi = primary.wifi, wifi.isEmpty == false {
            networkWiFiInterfaceName = wifi
        } else if counters.keys.contains("en0") {
            networkWiFiInterfaceName = "en0"
        } else if let firstEN = counters.keys.sorted().first(where: { $0.hasPrefix("en") }) {
            networkWiFiInterfaceName = firstEN
        }

        if let ethernet = primary.ethernet,
           ethernet.isEmpty == false,
           ethernet != networkWiFiInterfaceName {
            networkEthernetInterfaceName = ethernet
        } else if let firstEN = counters.keys.sorted().first(where: { $0.hasPrefix("en") && $0 != networkWiFiInterfaceName }) {
            networkEthernetInterfaceName = firstEN
        }

        networkLastInterfaceRefresh = now
    }

    func primaryInterfacesFromNetworkSetup() -> (wifi: String?, ethernet: String?) {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-listallhardwareports"]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return (nil, nil)
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let output = String(data: outputData, encoding: .utf8),
              output.isEmpty == false else {
            return (nil, nil)
        }

        var wifi: String?
        var ethernet: String?
        var currentHardwarePort: String?

        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("Hardware Port:") {
                currentHardwarePort = line.replacingOccurrences(of: "Hardware Port:", with: "").trimmingCharacters(in: .whitespaces)
                continue
            }
            if line.hasPrefix("Device:") {
                let device = line.replacingOccurrences(of: "Device:", with: "").trimmingCharacters(in: .whitespaces)
                guard device.isEmpty == false else { continue }
                let port = (currentHardwarePort ?? "").lowercased()
                if (port.contains("wi-fi") || port.contains("wifi")) && wifi == nil {
                    wifi = device
                } else if port.contains("ethernet") && ethernet == nil {
                    ethernet = device
                }
                currentHardwarePort = nil
            }
        }

        return (wifi, ethernet)
    }

    func refreshPrivateIPAddress() {
        if let wifiIP = ipv4Address(for: networkWiFiInterfaceName), wifiIP.isEmpty == false {
            networkWiFiPrivateIPAddress = wifiIP
        } else {
            networkWiFiPrivateIPAddress = L10n.networkNoData
        }

        if let ethernetIP = ipv4Address(for: networkEthernetInterfaceName), ethernetIP.isEmpty == false {
            networkEthernetPrivateIPAddress = ethernetIP
        } else {
            networkEthernetPrivateIPAddress = L10n.networkNoData
        }
    }

    func ipv4Address(for interfaceName: String) -> String? {
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let firstAddress = ifaddrPointer else {
            return nil
        }
        defer { freeifaddrs(ifaddrPointer) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while let ifa = cursor?.pointee {
            defer { cursor = ifa.ifa_next }
            guard let namePtr = ifa.ifa_name else { continue }
            let name = String(cString: namePtr)
            guard name == interfaceName else { continue }
            guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            if result == 0 {
                let ip = String(cString: host)
                if ip.isEmpty == false {
                    return ip
                }
            }
        }
        return nil
    }

    func refreshNetworkThroughput() {
        let now = Date()
        let counters = networkInterfaceByteCounters()

        defer {
            networkLastCounters = counters
            networkLastSampleDate = now
        }

        guard let previousSampleDate = networkLastSampleDate else {
            networkWiFiDownloadBytesPerSecond = 0
            networkWiFiUploadBytesPerSecond = 0
            networkEthernetDownloadBytesPerSecond = 0
            networkEthernetUploadBytesPerSecond = 0
            return
        }

        let deltaTime = max(0.001, now.timeIntervalSince(previousSampleDate))

        let wifiCurrent = counters[networkWiFiInterfaceName]
        let wifiPrevious = networkLastCounters[networkWiFiInterfaceName]
        let ethernetCurrent = counters[networkEthernetInterfaceName]
        let ethernetPrevious = networkLastCounters[networkEthernetInterfaceName]

        let wifiDownload = bytesPerSecond(current: wifiCurrent?.rxBytes, previous: wifiPrevious?.rxBytes, deltaTime: deltaTime)
        let wifiUpload = bytesPerSecond(current: wifiCurrent?.txBytes, previous: wifiPrevious?.txBytes, deltaTime: deltaTime)
        let ethernetDownload = bytesPerSecond(current: ethernetCurrent?.rxBytes, previous: ethernetPrevious?.rxBytes, deltaTime: deltaTime)
        let ethernetUpload = bytesPerSecond(current: ethernetCurrent?.txBytes, previous: ethernetPrevious?.txBytes, deltaTime: deltaTime)

        networkWiFiDownloadBytesPerSecond = smoothedSpeed(previous: networkWiFiDownloadBytesPerSecond, current: wifiDownload)
        networkWiFiUploadBytesPerSecond = smoothedSpeed(previous: networkWiFiUploadBytesPerSecond, current: wifiUpload)
        networkEthernetDownloadBytesPerSecond = smoothedSpeed(previous: networkEthernetDownloadBytesPerSecond, current: ethernetDownload)
        networkEthernetUploadBytesPerSecond = smoothedSpeed(previous: networkEthernetUploadBytesPerSecond, current: ethernetUpload)
    }

    func bytesPerSecond(current: UInt64?, previous: UInt64?, deltaTime: TimeInterval) -> Double {
        guard let current, let previous else { return 0 }
        if current < previous { return 0 }
        return Double(current - previous) / deltaTime
    }

    func smoothedSpeed(previous: Double, current: Double) -> Double {
        (previous * 0.65) + (current * 0.35)
    }

    func networkInterfaceByteCounters() -> [String: (rxBytes: UInt64, txBytes: UInt64)] {
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPointer) == 0, let firstAddress = ifaddrPointer else {
            return [:]
        }
        defer { freeifaddrs(ifaddrPointer) }

        var result: [String: (rxBytes: UInt64, txBytes: UInt64)] = [:]
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddress

        while let ifa = cursor?.pointee {
            defer { cursor = ifa.ifa_next }
            guard let namePtr = ifa.ifa_name else { continue }
            let name = String(cString: namePtr)
            let flags = Int32(ifa.ifa_flags)
            if (flags & IFF_LOOPBACK) != 0 { continue }
            guard let dataPtr = ifa.ifa_data?.assumingMemoryBound(to: if_data.self) else { continue }

            let rx = UInt64(dataPtr.pointee.ifi_ibytes)
            let tx = UInt64(dataPtr.pointee.ifi_obytes)
            if let existing = result[name] {
                result[name] = (max(existing.rxBytes, rx), max(existing.txBytes, tx))
            } else {
                result[name] = (rx, tx)
            }
        }

        return result
    }

    func refreshPublicIPAddressIfNeeded(force: Bool) {
        let now = Date()
        if force == false,
           let lastRefresh = networkLastPublicIPRefresh,
           now.timeIntervalSince(lastRefresh) < 120 {
            return
        }
        if networkPublicIPFetchInFlight {
            return
        }

        networkPublicIPFetchInFlight = true
        networkLastPublicIPRefresh = now

        Task {
            let fetchedIP = await fetchPublicIPAddress()
            await MainActor.run {
                if let fetchedIP, fetchedIP.isEmpty == false {
                    networkPublicIPAddress = fetchedIP
                } else if networkPublicIPAddress == "-" {
                    networkPublicIPAddress = L10n.networkNoData
                }
                networkPublicIPFetchInFlight = false
            }
        }
    }

    func fetchPublicIPAddress() async -> String? {
        guard let url = URL(string: "https://api64.ipify.org?format=text") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let text = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  text.isEmpty == false else {
                return nil
            }
            return text
        } catch {
            return nil
        }
    }

    func formattedNetworkSpeed(_ bytesPerSecond: Double) -> String {
        let clamped = max(0, bytesPerSecond)
        if clamped < 1024 {
            return String(format: "%.0f B/s", clamped)
        }
        if clamped < 1024 * 1024 {
            return String(format: "%.1f KB/s", clamped / 1024)
        }
        if clamped < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", clamped / (1024 * 1024))
        }
        return String(format: "%.2f GB/s", clamped / (1024 * 1024 * 1024))
    }

    func cpuAndCommandByPID() -> [pid_t: (cpuPercent: Double, command: String)] {
        guard let output = runPS(arguments: ["-A", "-o", "pid=,%cpu=,comm="])
            ?? runPS(arguments: ["-eo", "pid=,%cpu=,comm="]) else {
            return [:]
        }

        var result: [pid_t: (cpuPercent: Double, command: String)] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let parts = line.split(maxSplits: 2, whereSeparator: \.isWhitespace)
            guard parts.count >= 2,
                  let pid = pid_t(String(parts[0])) else { continue }

            let cpuText = String(parts[1]).replacingOccurrences(of: ",", with: ".")
            guard let cpu = Double(cpuText) else { continue }

            let fullCommand = parts.count >= 3
                ? String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            let displayName = URL(fileURLWithPath: fullCommand).lastPathComponent
            let command = displayName.isEmpty ? (fullCommand.isEmpty ? "process-\(pid)" : fullCommand) : displayName
            result[pid] = (cpuPercent: max(0, cpu), command: command)
        }

        return result
    }

    func runPS(arguments: [String]) -> String? {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        env["LC_ALL"] = "C"
        env["LANG"] = "C"
        process.environment = env
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        guard let output = String(data: outputData, encoding: .utf8), output.isEmpty == false else {
            return nil
        }
        return output
    }

    func cpuUsageByPID() -> [pid_t: Double] {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-A", "-o", "pid=,%cpu="]
        var env = ProcessInfo.processInfo.environment
        env["LC_ALL"] = "C"
        env["LANG"] = "C"
        process.environment = env
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return [:]
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [:] }
        guard let output = String(data: outputData, encoding: .utf8), output.isEmpty == false else {
            return [:]
        }

        var result: [pid_t: Double] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let columns = line.split(whereSeparator: \.isWhitespace)
            guard columns.count >= 2,
                  let pid = pid_t(String(columns[0])) else { continue }
            let cpuText = String(columns[1]).replacingOccurrences(of: ",", with: ".")
            guard let cpu = Double(cpuText) else { continue }
            result[pid] = max(0, cpu)
        }

        return result
    }

    var memoryUsageText: String {
        let usedText = USBVolumeMonitor.compactByteString(memoryUsedBytes)
        let totalText = USBVolumeMonitor.compactByteString(memoryTotalBytes)
        return String(format: "RAM %.1f%%  %@/%@", memoryUsagePercent, usedText, totalText)
    }

    func refreshMemoryUsage() {
        let total = Int64(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = Int64(vm_kernel_page_size)
        let free = Int64(stats.free_count) * pageSize
        let inactive = Int64(stats.inactive_count) * pageSize
        let speculative = Int64(stats.speculative_count) * pageSize
        let reclaimable = max(0, inactive + speculative)
        let used = max(0, total - free - reclaimable)

        memoryTotalBytes = total
        memoryUsedBytes = min(total, used)
        memoryUsagePercent = max(0, min(100, (Double(memoryUsedBytes) / Double(total)) * 100))
    }

    func startHousekeepingTimer() {
        stopHousekeepingTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                refreshSystemAudioState(triggerOnMuteTransition: true)
                if utilityMode == .audio {
                    refreshAudioDeviceName()
                } else if utilityMode == .network {
                    refreshNetworkModeData(forcePublicIPRefresh: false)
                } else if utilityMode == .cpu {
                    refreshCPUUsage()
                } else if utilityMode == .apps {
                    refreshAppsMonitorData()
                }
                if topMode == .weather {
                    refreshWeatherDataIfNeeded(force: false)
                }
            }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        housekeepingTimer = timer
    }

    func stopHousekeepingTimer() {
        housekeepingTimer?.invalidate()
        housekeepingTimer = nil
    }

    func refreshSystemAudioState(triggerOnMuteTransition: Bool) {
        if let scalar = currentSystemVolumeScalar() {
            systemVolumePercent = max(0, min(100, Double(scalar) * 100))
        }

        let isMuted = currentSystemMuted() ?? (systemVolumePercent <= 0.0001)
        if let previous = lastKnownSystemMuted,
           previous == false,
           isMuted == true,
           triggerOnMuteTransition {
            if enabledUtilityModes.contains(.audio) {
                utilityMode = .audio
                triggerFlash()
            }
        }
        lastKnownSystemMuted = isMuted
    }

    func adjustSystemVolumeFromScroll(deltaY: CGFloat) {
        guard deltaY != 0 else { return }
        let direction: Float32 = deltaY > 0 ? 1 : -1
        let step: Float32 = 0.02
        let current = currentSystemVolumeScalar() ?? Float32(systemVolumePercent / 100)
        let target = max(0, min(1, current + (direction * step)))
        if setSystemVolumeScalar(target) {
            systemVolumePercent = Double(target) * 100
            lastKnownSystemMuted = target <= 0.0001
        } else {
            refreshSystemAudioState(triggerOnMuteTransition: false)
        }
    }

    func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    func currentSystemVolumeScalar() -> Float32? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }

        if let scalar = getDeviceVolumeScalar(deviceID: deviceID, element: kAudioObjectPropertyElementMain) {
            return scalar
        }

        let channel1 = getDeviceVolumeScalar(deviceID: deviceID, element: 1)
        let channel2 = getDeviceVolumeScalar(deviceID: deviceID, element: 2)

        switch (channel1, channel2) {
        case let (left?, right?):
            return (left + right) / 2
        case let (left?, nil):
            return left
        case let (nil, right?):
            return right
        default:
            return nil
        }
    }

    func currentSystemMuted() -> Bool? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }

        if let muted = getDeviceMute(deviceID: deviceID, element: kAudioObjectPropertyElementMain) {
            return muted
        }

        let channel1 = getDeviceMute(deviceID: deviceID, element: 1)
        let channel2 = getDeviceMute(deviceID: deviceID, element: 2)

        switch (channel1, channel2) {
        case let (left?, right?):
            return left || right
        case let (left?, nil):
            return left
        case let (nil, right?):
            return right
        default:
            return nil
        }
    }

    func setSystemVolumeScalar(_ scalar: Float32) -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }
        let clamped = max(0, min(1, scalar))

        if setDeviceVolumeScalar(deviceID: deviceID, element: kAudioObjectPropertyElementMain, value: clamped) {
            return true
        }

        let leftSet = setDeviceVolumeScalar(deviceID: deviceID, element: 1, value: clamped)
        let rightSet = setDeviceVolumeScalar(deviceID: deviceID, element: 2, value: clamped)
        return leftSet || rightSet
    }

    func getDeviceVolumeScalar(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Float32? {
        var volume = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )

        guard AudioObjectHasProperty(deviceID, &address) else { return nil }

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &volume
        )
        guard status == noErr else { return nil }
        return max(0, min(1, volume))
    }

    func setDeviceVolumeScalar(deviceID: AudioDeviceID, element: AudioObjectPropertyElement, value: Float32) -> Bool {
        var volume = value
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )

        guard AudioObjectHasProperty(deviceID, &address) else { return false }

        let status = AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float32>.size),
            &volume
        )
        return status == noErr
    }

    func getDeviceMute(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Bool? {
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )

        guard AudioObjectHasProperty(deviceID, &address) else { return nil }

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &mute
        )
        guard status == noErr else { return nil }
        return mute != 0
    }


}
