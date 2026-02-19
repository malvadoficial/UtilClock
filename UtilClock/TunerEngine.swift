//
//  TunerEngine.swift
//  UtilClock
//

import Foundation

#if os(macOS)
import AVFoundation
import Combine
import CoreAudio
import AppKit

struct AudioInputDevice: Identifiable, Equatable {
    let id: UInt32
    let name: String
}

struct AudioInputSource: Identifiable, Equatable {
    let id: UInt32
    let name: String
}

@MainActor
final class TunerEngine: ObservableObject {
    @Published private(set) var inputs: [AudioInputDevice] = []
    @Published private(set) var selectedInputID: UInt32?
    @Published private(set) var inputSources: [AudioInputSource] = []
    @Published private(set) var selectedInputSourceID: UInt32?
    @Published private(set) var frequency: Double = 0
    @Published private(set) var noteName: String = "--"
    @Published private(set) var cents: Double = 0
    @Published private(set) var signalLevel: Double = 0
    @Published private(set) var detectedChordName: String = "--"
    @Published private(set) var detectedChordConfidence: Double = 0
    @Published private(set) var detectedChordNotes: [String] = []
    @Published private(set) var isRunning = false
    @Published private(set) var permissionDenied = false

    private let engine = AVAudioEngine()
    private var tapInstalled = false
    private let defaults = UserDefaults.standard
    private let selectedInputKey = "tuner.selectedInputID"
    private let selectedSourcePrefix = "tuner.selectedSourceID."
    private let virtualSourceBaseID: UInt32 = 10_000_000
    private var recentMidiValues: [Double] = []
    private var smoothedMidi: Double?
    private var smoothedChordChroma: [Double] = Array(repeating: 0, count: 12)

    init() {
        refreshInputs()
    }

    func refreshInputs() {
        let discovered = allInputDevices().sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        inputs = discovered

        let savedInput = UInt32(defaults.integer(forKey: selectedInputKey))
        let defaultInput = currentDefaultInputDeviceID()
        if savedInput != 0, discovered.contains(where: { $0.id == savedInput }) {
            selectedInputID = savedInput
        } else if let defaultInput, discovered.contains(where: { $0.id == defaultInput }) {
            selectedInputID = defaultInput
        } else {
            selectedInputID = discovered.first?.id
        }
        refreshInputSources()
    }

    func start() {
        if isRunning { return }
        guard ensureOrRequestMicrophonePermission() else { return }

        refreshInputs()
        installTapIfNeeded()
        engine.prepare()

        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func requestMicrophonePermissionFromUI() {
        _ = ensureOrRequestMicrophonePermission()
    }

    func stop() {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.stop()
        isRunning = false
        resetDetectionState()
    }

    func selectInput(_ deviceID: UInt32) {
        guard setDefaultInputDeviceID(deviceID) else { return }
        selectedInputID = deviceID
        defaults.set(Int(deviceID), forKey: selectedInputKey)
        refreshInputSources()
        if isRunning {
            stop()
            start()
        }
    }

    func selectInputSource(_ sourceID: UInt32) {
        guard let deviceID = selectedInputID else { return }
        if isVirtualSourceID(sourceID) == false {
            guard setInputDataSource(deviceID: deviceID, sourceID: sourceID) else { return }
        }
        selectedInputSourceID = sourceID
        defaults.set(Int(sourceID), forKey: selectedSourceKey(for: deviceID))
        refreshInputSources()
        if isRunning {
            stop()
            start()
        }
    }

    private func installTapIfNeeded() {
        guard tapInstalled == false else { return }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else { return }
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer, sampleRate: format.sampleRate)
        }
        tapInstalled = true
    }

    private func process(buffer: AVAudioPCMBuffer, sampleRate: Double) {
        let frameCount = Int(buffer.frameLength)
        guard frameCount >= 1024 else { return }
        let channelCount = Int(buffer.format.channelCount)
        if channelCount <= 0 { return }

        guard let mono = monoSamples(from: buffer) else { return }

        let rms = sqrt(mono.reduce(0.0) { $0 + ($1 * $1) } / Float(frameCount))
        let level = min(1.0, Double(rms) * 8.0)

        guard rms > 0.003 else {
            DispatchQueue.main.async { [weak self] in
                self?.signalLevel = level
                self?.frequency = 0
                self?.noteName = "--"
                self?.cents = 0
                self?.detectedChordName = "--"
                self?.detectedChordConfidence = 0
                self?.detectedChordNotes = []
            }
            recentMidiValues.removeAll(keepingCapacity: true)
            smoothedMidi = nil
            smoothedChordChroma = Array(repeating: 0, count: 12)
            return
        }

        guard let detection = detectPitchAutocorrelation(samples: mono, sampleRate: sampleRate) else {
            DispatchQueue.main.async { [weak self] in
                self?.signalLevel = level
                self?.frequency = 0
                self?.noteName = "--"
                self?.cents = 0
            }
            return
        }

        let stabilized = stabilizedFrequency(from: detection.frequency, confidence: detection.clarity)
        let note = noteData(for: stabilized)
        let chord = detectChord(samples: mono, sampleRate: sampleRate)
        DispatchQueue.main.async { [weak self] in
            self?.signalLevel = level
            self?.frequency = stabilized
            self?.noteName = note.name
            self?.cents = note.cents
            self?.detectedChordName = chord.name
            self?.detectedChordConfidence = chord.confidence
            self?.detectedChordNotes = chord.notes
        }
    }

    private func resetDetectionState() {
        recentMidiValues.removeAll(keepingCapacity: true)
        smoothedMidi = nil
        smoothedChordChroma = Array(repeating: 0, count: 12)
        frequency = 0
        noteName = "--"
        cents = 0
        signalLevel = 0
        detectedChordName = "--"
        detectedChordConfidence = 0
        detectedChordNotes = []
    }

    private func monoSamples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        if frameCount == 0 || channelCount == 0 { return nil }

        let selectedChannelIndex: Int? = {
            if let selectedSourceID = selectedInputSourceID, isVirtualSourceID(selectedSourceID) {
                let selectedChannel = Int(selectedSourceID - virtualSourceBaseID)
                return max(0, min(channelCount - 1, selectedChannel - 1))
            }
            return nil
        }()

        var mono = Array(repeating: Float(0), count: frameCount)

        if let channels = buffer.floatChannelData {
            if let selected = selectedChannelIndex {
                let channel = channels[selected]
                for i in 0..<frameCount { mono[i] = channel[i] }
            } else {
                for c in 0..<channelCount {
                    let channel = channels[c]
                    for i in 0..<frameCount { mono[i] += channel[i] }
                }
                let inv = 1.0 / Float(channelCount)
                for i in 0..<frameCount { mono[i] *= inv }
            }
            return mono
        }

        if let channels = buffer.int16ChannelData {
            let scale: Float = 1.0 / 32768.0
            if let selected = selectedChannelIndex {
                let channel = channels[selected]
                for i in 0..<frameCount { mono[i] = Float(channel[i]) * scale }
            } else {
                for c in 0..<channelCount {
                    let channel = channels[c]
                    for i in 0..<frameCount { mono[i] += Float(channel[i]) * scale }
                }
                let inv = 1.0 / Float(channelCount)
                for i in 0..<frameCount { mono[i] *= inv }
            }
            return mono
        }

        if let channels = buffer.int32ChannelData {
            let scale: Float = 1.0 / 2147483648.0
            if let selected = selectedChannelIndex {
                let channel = channels[selected]
                for i in 0..<frameCount { mono[i] = Float(channel[i]) * scale }
            } else {
                for c in 0..<channelCount {
                    let channel = channels[c]
                    for i in 0..<frameCount { mono[i] += Float(channel[i]) * scale }
                }
                let inv = 1.0 / Float(channelCount)
                for i in 0..<frameCount { mono[i] *= inv }
            }
            return mono
        }

        return nil
    }

    private func detectPitchAutocorrelation(samples: [Float], sampleRate: Double) -> (frequency: Double, clarity: Double)? {
        let n = samples.count
        if n < 1024 { return nil }

        let mean = samples.reduce(0, +) / Float(n)
        var centered = Array(repeating: Float(0), count: n)
        for i in 0..<n {
            centered[i] = samples[i] - mean
        }

        let minFreq = 30.0
        let maxFreq = 1200.0
        let minLag = max(2, Int(sampleRate / maxFreq))
        let maxLag = min(n - 2, Int(sampleRate / minFreq))
        if minLag >= maxLag { return nil }

        var bestLag = 0
        var bestCorr = Float(-1)
        var corrValues = Array(repeating: Float(0), count: maxLag + 1)

        for lag in minLag...maxLag {
            var sum: Float = 0
            var normA: Float = 0
            var normB: Float = 0
            let limit = n - lag
            for i in 0..<limit {
                let a = centered[i]
                let b = centered[i + lag]
                sum += a * b
                normA += a * a
                normB += b * b
            }
            let denom = sqrt(normA * normB) + 1e-9
            let corr = sum / denom
            corrValues[lag] = corr
            if corr > bestCorr {
                bestCorr = corr
                bestLag = lag
            }
        }

        if bestLag == 0 || bestCorr < 0.35 { return nil }
        var refinedLag = Double(bestLag)
        if bestLag > minLag, bestLag < maxLag {
            let ym1 = Double(corrValues[bestLag - 1])
            let y0 = Double(corrValues[bestLag])
            let yp1 = Double(corrValues[bestLag + 1])
            let denom = (ym1 - (2.0 * y0) + yp1)
            if abs(denom) > 1e-12 {
                let delta = 0.5 * (ym1 - yp1) / denom
                if abs(delta) <= 1.0 {
                    refinedLag += delta
                }
            }
        }

        let freq = sampleRate / refinedLag
        if freq < minFreq || freq > maxFreq { return nil }
        return (freq, Double(bestCorr))
    }

    private func stabilizedFrequency(from detected: Double, confidence: Double) -> Double {
        let detectedMidi = 69.0 + (12.0 * log2(detected / 440.0))

        if let previous = smoothedMidi {
            // Fast retarget when switching strings (large pitch jump).
            if abs(detectedMidi - previous) > 2.5 {
                recentMidiValues.removeAll(keepingCapacity: true)
                recentMidiValues.append(detectedMidi)
                smoothedMidi = detectedMidi
                return 440.0 * pow(2.0, (detectedMidi - 69.0) / 12.0)
            }
        }

        recentMidiValues.append(detectedMidi)
        if recentMidiValues.count > 5 {
            recentMidiValues.removeFirst(recentMidiValues.count - 5)
        }

        let sorted = recentMidiValues.sorted()
        let median = sorted[sorted.count / 2]

        if let previous = smoothedMidi {
            let delta = median - previous
            let limitedDelta = max(-0.65, min(0.65, delta))

            let confidenceBoost = max(0.0, min(1.0, (confidence - 0.35) / 0.55))
            let alpha = 0.20 + (confidenceBoost * 0.40)

            let next = previous + (limitedDelta * alpha)
            smoothedMidi = next
            return 440.0 * pow(2.0, (next - 69.0) / 12.0)
        } else {
            smoothedMidi = median
            return 440.0 * pow(2.0, (median - 69.0) / 12.0)
        }
    }

    private func noteData(for frequency: Double) -> (name: String, cents: Double) {
        let midi = 69.0 + (12.0 * log2(frequency / 440.0))
        let nearest = round(midi)
        let cents = (midi - nearest) * 100.0
        let names = Self.noteNames
        let noteIndex = Int(nearest).positiveModulo(12)
        let octave = (Int(nearest) / 12) - 1
        return ("\(names[noteIndex])\(octave)", cents)
    }

    private func detectChord(samples: [Float], sampleRate: Double) -> (name: String, confidence: Double, notes: [String]) {
        guard samples.count >= 1024 else {
            return ("--", 0, [])
        }

        var chroma = Array(repeating: 0.0, count: 12)
        for midi in 40...88 {
            let fundamental = midiFrequency(midi)
            let secondHarmonic = fundamental * 2.0
            if secondHarmonic >= sampleRate * 0.48 { continue }

            let mag1 = goertzelMagnitude(samples: samples, targetFrequency: fundamental, sampleRate: sampleRate)
            let mag2 = goertzelMagnitude(samples: samples, targetFrequency: secondHarmonic, sampleRate: sampleRate)
            let energy = mag1 + (mag2 * 0.35)
            if energy <= 0 { continue }
            let pc = midi.positiveModulo(12)
            chroma[pc] += energy
        }

        let maxValue = chroma.max() ?? 0
        guard maxValue > 0 else {
            return ("--", 0, [])
        }

        for i in 0..<12 {
            chroma[i] /= maxValue
            smoothedChordChroma[i] = (smoothedChordChroma[i] * 0.62) + (chroma[i] * 0.38)
        }
        let normalized = normalizeChroma(smoothedChordChroma)
        let activePitchClasses = normalized.enumerated()
            .filter { $0.element >= 0.24 }
            .sorted { $0.element > $1.element }

        if activePitchClasses.count < 2 {
            return ("--", 0, [])
        }

        let notes = activePitchClasses.prefix(5).map { Self.noteNames[$0.offset] }
        guard let best = bestMatchingChord(from: normalized) else {
            return ("--", 0, notes)
        }

        if best.confidence < 0.28 {
            return ("--", max(0, best.confidence), notes)
        }

        return (best.name, min(1, best.confidence), notes)
    }

    private func bestMatchingChord(from chroma: [Double]) -> (name: String, confidence: Double)? {
        guard chroma.count == 12 else { return nil }

        let templates: [(suffix: String, intervals: [Int])] = [
            ("", [0, 4, 7]),
            ("m", [0, 3, 7]),
            ("7", [0, 4, 7, 10]),
            ("maj7", [0, 4, 7, 11]),
            ("m7", [0, 3, 7, 10]),
            ("sus2", [0, 2, 7]),
            ("sus4", [0, 5, 7]),
            ("dim", [0, 3, 6]),
            ("aug", [0, 4, 8]),
            ("6", [0, 4, 7, 9]),
            ("m6", [0, 3, 7, 9]),
            ("add9", [0, 2, 4, 7]),
            ("madd9", [0, 2, 3, 7]),
            ("9", [0, 2, 4, 7, 10]),
            ("m9", [0, 2, 3, 7, 10])
        ]

        var bestName = "--"
        var bestScore = -Double.infinity

        for root in 0..<12 {
            let rootName = Self.noteNames[root]
            for template in templates {
                let pcs = Set(template.intervals.map { (root + $0).positiveModulo(12) })
                if pcs.isEmpty { continue }

                var inSum = 0.0
                var inStrongCount = 0
                for pc in pcs {
                    let value = chroma[pc]
                    inSum += value
                    if value >= 0.22 { inStrongCount += 1 }
                }
                let inAvg = inSum / Double(pcs.count)
                let coverage = Double(inStrongCount) / Double(pcs.count)

                var outSum = 0.0
                var outCount = 0
                for pc in 0..<12 where pcs.contains(pc) == false {
                    outSum += chroma[pc]
                    outCount += 1
                }
                let outAvg = outCount > 0 ? outSum / Double(outCount) : 0
                let score = (inAvg * 0.74) + (coverage * 0.30) - (outAvg * 0.42)
                if score > bestScore {
                    bestScore = score
                    bestName = "\(rootName)\(template.suffix)"
                }
            }
        }

        if bestScore.isFinite == false {
            return nil
        }
        return (bestName, max(0, min(1, bestScore)))
    }

    private func normalizeChroma(_ values: [Double]) -> [Double] {
        guard let maxValue = values.max(), maxValue > 0 else {
            return Array(repeating: 0, count: 12)
        }
        return values.map { $0 / maxValue }
    }

    private func midiFrequency(_ midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    private func goertzelMagnitude(samples: [Float], targetFrequency: Double, sampleRate: Double) -> Double {
        let n = samples.count
        if n == 0 || targetFrequency <= 0 || targetFrequency >= sampleRate * 0.5 {
            return 0
        }

        let k = Int((Double(n) * targetFrequency / sampleRate).rounded())
        if k <= 0 || k >= (n / 2) { return 0 }

        let omega = (2.0 * Double.pi * Double(k)) / Double(n)
        let coefficient = 2.0 * cos(omega)

        var q0 = 0.0
        var q1 = 0.0
        var q2 = 0.0
        for sample in samples {
            q0 = coefficient * q1 - q2 + Double(sample)
            q2 = q1
            q1 = q0
        }

        let real = q1 - q2 * cos(omega)
        let imag = q2 * sin(omega)
        return sqrt((real * real) + (imag * imag)) / Double(n)
    }

    private func allInputDevices() -> [AudioInputDevice] {
        var propertySize: UInt32 = 0
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &propertySize) == noErr else {
            return []
        }

        let count = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &propertySize, &deviceIDs) == noErr else {
            return []
        }

        return deviceIDs.compactMap { deviceID in
            guard hasInput(deviceID: deviceID) else { return nil }
            return AudioInputDevice(id: deviceID, name: deviceName(deviceID: deviceID))
        }
    }

    private func refreshInputSources() {
        guard let deviceID = selectedInputID else {
            inputSources = []
            selectedInputSourceID = nil
            return
        }

        var discovered = allInputSources(for: deviceID)
        discovered.append(contentsOf: channelInputSources(for: deviceID))
        inputSources = discovered

        let savedSource = UInt32(defaults.integer(forKey: selectedSourceKey(for: deviceID)))
        var selected: UInt32?
        if savedSource != 0, discovered.contains(where: { $0.id == savedSource }) {
            selected = savedSource
        } else if let current = currentInputDataSource(deviceID: deviceID),
                  discovered.contains(where: { $0.id == current }) {
            selected = current
        } else {
            selected = discovered.first?.id
        }

        if let selected {
            if isVirtualSourceID(selected) == false {
                _ = setInputDataSource(deviceID: deviceID, sourceID: selected)
            }
            defaults.set(Int(selected), forKey: selectedSourceKey(for: deviceID))
        }
        selectedInputSourceID = selected
    }

    private func allInputSources(for deviceID: UInt32) -> [AudioInputSource] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDataSources,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else { return [] }

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<UInt32>.size
        if count <= 0 { return [] }

        var sourceIDs = Array(repeating: UInt32(0), count: count)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &sourceIDs) == noErr else { return [] }

        return sourceIDs.map { sourceID in
            AudioInputSource(id: sourceID, name: inputSourceName(deviceID: deviceID, sourceID: sourceID))
        }
    }

    private func currentInputDataSource(deviceID: UInt32) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDataSource,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }

        var sourceID: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &sourceID) == noErr else { return nil }
        return sourceID
    }

    private func setInputDataSource(deviceID: UInt32, sourceID: UInt32) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDataSource,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else { return false }

        var mutableSource = sourceID
        return AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &mutableSource
        ) == noErr
    }

    private func inputSourceName(deviceID: UInt32, sourceID: UInt32) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDataSourceNameForIDCFString,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectHasProperty(deviceID, &address) else {
            return "Source \(sourceID)"
        }

        var mutableSourceID = sourceID
        var cfName: CFString?
        var status: OSStatus = noErr
        withUnsafeMutablePointer(to: &mutableSourceID) { sourcePtr in
            withUnsafeMutablePointer(to: &cfName) { namePtr in
                var translation = AudioValueTranslation(
                    mInputData: UnsafeMutableRawPointer(sourcePtr),
                    mInputDataSize: UInt32(MemoryLayout<UInt32>.size),
                    mOutputData: UnsafeMutableRawPointer(namePtr),
                    mOutputDataSize: UInt32(MemoryLayout<CFString?>.size)
                )
                var size = UInt32(MemoryLayout<AudioValueTranslation>.size)
                status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &translation)
            }
        }

        guard status == noErr else { return "Source \(sourceID)" }
        return (cfName as String?) ?? "Source \(sourceID)"
    }

    private func channelInputSources(for deviceID: UInt32) -> [AudioInputSource] {
        let count = inputChannelCount(deviceID: deviceID)
        guard count > 1 else { return [] }
        return (1...count).map { channel in
            AudioInputSource(id: virtualSourceBaseID + UInt32(channel), name: "Input \(channel)")
        }
    }

    private func inputChannelCount(deviceID: UInt32) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return 0 }

        let raw = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        let bufferList = raw.assumingMemoryBound(to: AudioBufferList.self)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferList) == noErr else { return 0 }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private func isVirtualSourceID(_ sourceID: UInt32) -> Bool {
        sourceID >= virtualSourceBaseID
    }

    private func selectedSourceKey(for deviceID: UInt32) -> String {
        "\(selectedSourcePrefix)\(deviceID)"
    }

    @discardableResult
    private func ensureOrRequestMicrophonePermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            permissionDenied = false
            return true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.permissionDenied = !granted
                    if granted { self.start() }
                }
            }
            return false
        default:
            permissionDenied = true
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
            return false
        }
    }

    private func hasInput(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return false }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { bufferList.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferList) == noErr else { return false }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        return buffers.contains { $0.mNumberChannels > 0 }
    }

    private func deviceName(deviceID: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var nameRef: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &nameRef) == noErr else {
            return "Input \(deviceID)"
        }
        return (nameRef?.takeUnretainedValue() as String?) ?? "Input \(deviceID)"
    }

    private func currentDefaultInputDeviceID() -> UInt32? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr else {
            return nil
        }
        return deviceID == 0 ? nil : deviceID
    }

    private func setDefaultInputDeviceID(_ deviceID: UInt32) -> Bool {
        var mutableID = AudioDeviceID(deviceID)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        return AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &mutableID
        ) == noErr
    }

    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
}

private extension Int {
    func positiveModulo(_ n: Int) -> Int {
        let m = self % n
        return m >= 0 ? m : (m + n)
    }
}
#endif
