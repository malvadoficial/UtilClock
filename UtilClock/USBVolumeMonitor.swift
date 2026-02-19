//
//  USBVolumeMonitor.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import Foundation

#if os(macOS)
import AppKit
import Combine

struct USBVolumeInfo: Identifiable {
    let id: String
    let label: String
    let totalBytes: Int64
    let freeBytes: Int64
    let fileSystem: String

    var totalText: String {
        USBVolumeMonitor.byteFormatter.string(fromByteCount: totalBytes)
    }

    var freeText: String {
        USBVolumeMonitor.byteFormatter.string(fromByteCount: freeBytes)
    }

    var totalCompactText: String {
        USBVolumeMonitor.compactByteString(totalBytes)
    }

    var freeCompactText: String {
        USBVolumeMonitor.compactByteString(freeBytes)
    }
}

@MainActor
final class USBVolumeMonitor: NSObject, ObservableObject {
    @Published private(set) var volumes: [USBVolumeInfo] = []
    @Published private(set) var storageVolumes: [USBVolumeInfo] = []

    private static let urlKeys: Set<URLResourceKey> = [
        .volumeNameKey,
        .volumeIsRemovableKey,
        .volumeIsInternalKey,
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey,
        .volumeLocalizedFormatDescriptionKey
    ]

    static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func compactByteString(_ bytes: Int64) -> String {
        let absBytes = max(0, Double(bytes))
        let units: [(Double, String)] = [
            (1_000_000_000_000, "T"),
            (1_000_000_000, "G"),
            (1_000_000, "M"),
            (1_000, "K")
        ]

        for (factor, suffix) in units where absBytes >= factor {
            let value = absBytes / factor
            let decimals = 2

            return "\(trimmedNumber(value, decimals: decimals))\(suffix)"
        }

        return "\(Int(absBytes))B"
    }

    private static func trimmedNumber(_ value: Double, decimals: Int) -> String {
        let format = "%.\(decimals)f"
        var text = String(format: format, value)

        if text.contains(".") {
            text = text.replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
        }

        return text
    }

    override init() {
        super.init()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(volumesDidChange(_:)), name: NSWorkspace.didMountNotification, object: nil)
        center.addObserver(self, selector: #selector(volumesDidChange(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        center.addObserver(self, selector: #selector(volumesDidChange(_:)), name: NSWorkspace.didRenameVolumeNotification, object: nil)
        reloadVolumes()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func volumesDidChange(_ notification: Notification) {
        reloadVolumes()
    }

    private func reloadVolumes() {
        guard let mountedURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(Self.urlKeys),
            options: [.skipHiddenVolumes]
        ) else {
            volumes = []
            storageVolumes = []
            return
        }

        typealias Candidate = (info: USBVolumeInfo, isRemovable: Bool, isInternal: Bool, path: String)
        let candidates = mountedURLs.compactMap { (url: URL) -> Candidate? in
            guard let values = try? url.resourceValues(forKeys: Self.urlKeys) else {
                return nil
            }

            let label = values.volumeName ?? url.lastPathComponent
            let (totalBytes, freeBytes) = Self.capacityInfo(for: url, values: values)
            let fileSystem = Self.fileSystemDescription(for: url, values: values)

            return (
                info: USBVolumeInfo(
                    id: url.path,
                    label: label,
                    totalBytes: max(0, totalBytes),
                    freeBytes: max(0, freeBytes),
                    fileSystem: fileSystem
                ),
                isRemovable: values.volumeIsRemovable == true,
                isInternal: values.volumeIsInternal == true,
                path: url.path
            )
        }
        .sorted { $0.info.label.localizedCaseInsensitiveCompare($1.info.label) == .orderedAscending }

        volumes = candidates
            .filter { candidate in
                candidate.isRemovable &&
                candidate.isInternal == false &&
                candidate.path.hasPrefix("/Volumes/") &&
                isStorageLabel(candidate.info.label) == false
            }
            .map(\.info)
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }

        let dedupedStorage = candidates
            .filter { isStorageLabel($0.info.label) }
            .reduce(into: [String: Candidate]()) { result, candidate in
                let key = normalizedStorageLabel(candidate.info.label)
                if let existing = result[key] {
                    if storageCandidateScore(candidate, key: key) > storageCandidateScore(existing, key: key) {
                        result[key] = candidate
                    }
                } else {
                    result[key] = candidate
                }
            }

        storageVolumes = dedupedStorage
            .values
            .map(\.info)
            .sorted { lhs, rhs in
                let lhsRank = storageSortRank(lhs.label)
                let rhsRank = storageSortRank(rhs.label)
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    private func storageSortRank(_ label: String) -> Int {
        let key = normalizedStorageLabel(label)
        if key == "macintosh hd" {
            return 0
        }
        if key == "externo" {
            return 1
        }
        if key == "time machine" {
            return 2
        }
        return 3
    }

    private func storageCandidateScore(_ candidate: (info: USBVolumeInfo, isRemovable: Bool, isInternal: Bool, path: String), key: String) -> Int64 {
        var score = candidate.info.totalBytes
        if key == "macintosh hd" && candidate.path == "/" {
            score += 1_000_000_000_000_000
        }
        return score
    }

    private func isStorageLabel(_ label: String) -> Bool {
        let key = normalizedStorageLabel(label)
        return key == "macintosh hd" || key == "externo" || key == "time machine"
    }

    private func normalizedStorageLabel(_ label: String) -> String {
        let lowered = label.lowercased()
        if lowered == "machintosh hd" {
            return "macintosh hd"
        }
        return lowered
    }

    private static func capacityInfo(for url: URL, values: URLResourceValues) -> (Int64, Int64) {
        var totalBytes = Int64(values.volumeTotalCapacity ?? 0)
        var freeBytes = Int64(0)

        if let available = values.volumeAvailableCapacity {
            freeBytes = Int64(available)
        } else if let important = values.volumeAvailableCapacityForImportantUsage {
            freeBytes = Int64(important)
        }

        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: url.path) {
            if totalBytes <= 0 {
                if let size = attributes[.systemSize] as? NSNumber {
                    totalBytes = size.int64Value
                } else if let size = attributes[.systemSize] as? Int64 {
                    totalBytes = size
                } else if let size = attributes[.systemSize] as? Int {
                    totalBytes = Int64(size)
                }
            }

            if freeBytes <= 0 {
                if let free = attributes[.systemFreeSize] as? NSNumber {
                    freeBytes = free.int64Value
                } else if let free = attributes[.systemFreeSize] as? Int64 {
                    freeBytes = free
                } else if let free = attributes[.systemFreeSize] as? Int {
                    freeBytes = Int64(free)
                }
            }
        }

        return (max(0, totalBytes), max(0, freeBytes))
    }

    private static func fileSystemDescription(for url: URL, values: URLResourceValues) -> String {
        if let localized = values.volumeLocalizedFormatDescription, localized.isEmpty == false {
            return localized
        }

        return L10n.unknownFileSystem
    }
}
#endif
