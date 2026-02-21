//
//  ContentView.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import SwiftUI
#if os(macOS)
import AppKit
import CoreAudio
import Darwin
import AVFoundation
import AVKit
import QuartzCore
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    #if os(macOS)
    private let gameLoopIntervalMs = 16
    private let gameLoopLeewayMs = 4
    private let startupDisplaySelectionKey = "utilclock.startup.selectedDisplayID"
    #endif
    private let preferredFullscreenKey = "utilclock.window.preferredFullscreen"

    #if os(macOS)
    private struct DisplayTarget: Identifiable {
        let id: UInt32
        let name: String
        let resolutionText: String
        let isMain: Bool
    }
    #endif

    private enum TopClockMode: CaseIterable, Hashable {
        case clock
        case worldClock
        case uptime
        case stopwatch
        case countdown
        case alarm

        var key: String {
            switch self {
            case .clock: return "clock"
            case .worldClock: return "worldClock"
            case .uptime: return "uptime"
            case .stopwatch: return "stopwatch"
            case .countdown: return "countdown"
            case .alarm: return "alarm"
            }
        }

        var next: TopClockMode {
            switch self {
            case .clock: return .worldClock
            case .worldClock: return .uptime
            case .uptime: return .stopwatch
            case .stopwatch: return .countdown
            case .countdown: return .alarm
            case .alarm: return .clock
            }
        }

        var previous: TopClockMode {
            switch self {
            case .clock: return .alarm
            case .worldClock: return .clock
            case .uptime: return .worldClock
            case .stopwatch: return .uptime
            case .countdown: return .stopwatch
            case .alarm: return .countdown
            }
        }
    }

    private enum UtilityMode: CaseIterable, Hashable {
        case usb
        case audio
        case storage
        case cpu
        case apps
        case processes
        case volume
        case metronome
        case tuner
        case chordDetect
        case chordFinder
        case pong
        case arkanoid
        case missileCommand
        case snake
        case todayInHistory
        case musicThought
        case rae
        case series

        var key: String {
            switch self {
            case .usb: return "usb"
            case .audio: return "audio"
            case .storage: return "storage"
            case .cpu: return "cpu"
            case .apps: return "apps"
            case .processes: return "processes"
            case .volume: return "volume"
            case .metronome: return "metronome"
            case .tuner: return "tuner"
            case .chordDetect: return "chordDetect"
            case .chordFinder: return "chordFinder"
            case .pong: return "pong"
            case .arkanoid: return "arkanoid"
            case .missileCommand: return "missileCommand"
            case .snake: return "snake"
            case .todayInHistory: return "todayInHistory"
            case .musicThought: return "musicThought"
            case .rae: return "rae"
            case .series: return "series"
            }
        }

        var next: UtilityMode {
            switch self {
            case .audio: return .usb
            case .usb: return .storage
            case .storage: return .cpu
            case .cpu: return .apps
            case .apps: return .processes
            case .processes: return .volume
            case .volume: return .metronome
            case .metronome: return .tuner
            case .tuner: return .chordDetect
            case .chordDetect: return .chordFinder
            case .chordFinder: return .pong
            case .pong: return .arkanoid
            case .arkanoid: return .missileCommand
            case .missileCommand: return .snake
            case .snake: return .todayInHistory
            case .todayInHistory: return .musicThought
            case .musicThought: return .rae
            case .rae: return .audio
            case .series: return .audio
            }
        }

        var previous: UtilityMode {
            switch self {
            case .audio: return .rae
            case .usb: return .audio
            case .storage: return .usb
            case .cpu: return .storage
            case .apps: return .cpu
            case .processes: return .apps
            case .volume: return .processes
            case .metronome: return .volume
            case .tuner: return .metronome
            case .chordDetect: return .tuner
            case .chordFinder: return .chordDetect
            case .pong: return .chordFinder
            case .arkanoid: return .pong
            case .missileCommand: return .arkanoid
            case .snake: return .missileCommand
            case .todayInHistory: return .snake
            case .musicThought: return .todayInHistory
            case .rae: return .musicThought
            case .series: return .rae
            }
        }
    }

    private enum SplitFullscreenTarget: Hashable {
        case none
        case top
        case bottom
    }

    private struct ChordVoicing: Identifiable {
        let id: String
        let frets: [Int]
        let fingers: [Int]
    }

    private struct ParsedChord {
        let symbol: String
        let lookupKey: String
        let rootPitchClass: Int
        let pitchClasses: Set<Int>
    }

    private struct ThisDayEvent: Identifiable {
        let id: String
        let month: Int
        let day: Int
        let year: Int
        let es: String
        let en: String
    }

    #if os(macOS)
    private struct RunningAppUsage: Identifiable {
        let id: Int32
        let name: String
        let cpuPercent: Double
        let icon: NSImage
    }

    private struct RunningProcessUsage: Identifiable {
        let id: Int32
        let name: String
        let cpuPercent: Double
    }

    private struct TopModeDropDelegate: DropDelegate {
        let target: TopClockMode
        @Binding var items: [TopClockMode]
        @Binding var draggedItem: TopClockMode?
        let onReorder: () -> Void

        func dropEntered(info: DropInfo) {
            guard let draggedItem,
                  draggedItem != target,
                  let from = items.firstIndex(of: draggedItem),
                  let to = items.firstIndex(of: target) else { return }

            withAnimation {
                items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? (to + 1) : to)
            }
            onReorder()
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            draggedItem = nil
            return true
        }
    }

    private struct UtilityModeDropDelegate: DropDelegate {
        let target: UtilityMode
        @Binding var items: [UtilityMode]
        @Binding var draggedItem: UtilityMode?
        let onReorder: () -> Void

        func dropEntered(info: DropInfo) {
            guard let draggedItem,
                  draggedItem != target,
                  let from = items.firstIndex(of: draggedItem),
                  let to = items.firstIndex(of: target) else { return }

            withAnimation {
                items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? (to + 1) : to)
            }
            onReorder()
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            DropProposal(operation: .move)
        }

        func performDrop(info: DropInfo) -> Bool {
            draggedItem = nil
            return true
        }
    }
    #endif

    private enum MissileTargetKind {
        case city(Int)
        case base(Int)
    }

    private struct MissileEnemy: Identifiable {
        let id = UUID()
        let start: CGPoint
        let target: CGPoint
        let targetKind: MissileTargetKind
        var position: CGPoint
        var velocity: CGVector
    }

    private struct MissilePlayerRocket: Identifiable {
        let id = UUID()
        let start: CGPoint
        let target: CGPoint
        var position: CGPoint
        var velocity: CGVector
    }

    private struct MissileExplosion: Identifiable {
        let id = UUID()
        let center: CGPoint
        var age: CGFloat
        let maxAge: CGFloat
        let maxRadius: CGFloat
    }

    private struct OnThisDayResponse: Decodable {
        struct Entry: Decodable {
            let text: String?
            let year: Int?
        }

        let selected: [Entry]?
        let events: [Entry]?
        let births: [Entry]?
        let deaths: [Entry]?
    }

    private struct MusicThoughtQuote: Identifiable, Equatable {
        let id: String
        let quote: String
        let author: String
        let linkPath: String
    }

    private enum DisplayPalette: String, CaseIterable {
        case green
        case amber
        case cyan
        case white

        var label: String {
            switch self {
            case .green: return "green"
            case .amber: return "amber"
            case .cyan: return "cyan"
            case .white: return "white"
            }
        }

        var color: Color {
            switch self {
            case .green:
                return Color(red: 0.6, green: 1.0, blue: 0.72)
            case .amber:
                return Color(red: 1.0, green: 0.84, blue: 0.4)
            case .cyan:
                return Color(red: 0.56, green: 0.96, blue: 1.0)
            case .white:
                return Color(red: 0.9, green: 0.95, blue: 0.9)
            }
        }

        var dimColor: Color {
            switch self {
            case .green:
                return Color(red: 0.45, green: 0.8, blue: 0.57)
            case .amber:
                return Color(red: 0.84, green: 0.68, blue: 0.3)
            case .cyan:
                return Color(red: 0.4, green: 0.76, blue: 0.82)
            case .white:
                return Color(red: 0.72, green: 0.77, blue: 0.72)
            }
        }
    }

    @StateObject private var viewModel = ClockViewModel()
    @State private var topMode: TopClockMode = .clock
    @State private var utilityMode: UtilityMode = .audio
    @State private var displayPalette: DisplayPalette = .green
    @State private var showSettings = false
    @State private var showQuitAppConfirmation = false
    @State private var enabledTopModes: Set<TopClockMode> = Set(TopClockMode.allCases)
    @State private var enabledUtilityModes: Set<UtilityMode> = Set(UtilityMode.allCases)
    @State private var topModeOrder: [TopClockMode] = TopClockMode.allCases
    @State private var utilityModeOrder: [UtilityMode] = UtilityMode.allCases
    @State private var countdownSetHours = 0
    @State private var countdownSetMinutes = 0
    @State private var countdownSetSeconds = 0
    @State private var countdownInitialSeconds = 0
    @State private var countdownRemainingSeconds = 0
    @State private var countdownRunning = false
    @State private var stopwatchRunning = false
    @State private var stopwatchAccumulatedCentiseconds = 0
    @State private var stopwatchStartDate: Date?
    @State private var stopwatchPrestartCountdownEnabled = false
    @State private var stopwatchPrestartInProgress = false
    @State private var stopwatchPrestartDisplayValue: Int?
    @State private var stopwatchPrestartTask: Task<Void, Never>?
    @State private var alarmSetHours = 0
    @State private var alarmSetMinutes = 0
    @State private var alarmEnabled = false
    @State private var selectedWorldCityIndex = 0
    @State private var splitFullscreenTarget: SplitFullscreenTarget = .none
    @State private var preferredFullscreen = true
    @State private var lastTriggeredAlarmSecondKey: String?
    @State private var selectedAudioDeviceName = L10n.noAudioDevice
    @State private var cpuUsagePercent: Double = 0
    @State private var memoryUsagePercent: Double = 0
    @State private var memoryUsedBytes: Int64 = 0
    @State private var memoryTotalBytes: Int64 = 0
    @State private var systemVolumePercent: Double = 0
    @State private var metronomeBPM = 120
    @State private var metronomeRunning = false
    @State private var metronomePulseActive = false
    @State private var metronomeBeatIndex = 0
    @State private var metronomeNumerator = 4
    @State private var metronomeDenominator = 4
    @State private var chordInput = "Am"
    @State private var chordVoicingIndex = 0
    @State private var parsedChord: ParsedChord?
    @State private var chordGeneratedVoicings: [ChordVoicing] = []
    #if os(macOS)
    @State private var draggedTopMode: TopClockMode?
    @State private var draggedUtilityMode: UtilityMode?
    @State private var hostWindow: NSWindow?
    @State private var runningAppsUsage: [RunningAppUsage] = []
    @State private var runningProcessesUsage: [RunningProcessUsage] = []
    @StateObject private var usbMonitor = USBVolumeMonitor()
    @State private var flashOpacity: Double = 0
    @State private var knownVolumeIDs: Set<String> = []
    @State private var lastCPUTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    @State private var lastKnownSystemMuted: Bool?
    @State private var countdownAlarmActive = false
    @State private var countdownAlarmTimer: Timer?
    @State private var countdownAlarmFlashTimer: Timer?
    @State private var countdownAlarmStopWorkItem: DispatchWorkItem?
    @State private var countdownAlarmPlayer: AVAudioPlayer?
    @State private var countdownBeepPlayer: AVAudioPlayer?
    @State private var metronomeTickPlayer: AVAudioPlayer?
    @State private var metronomeStrongTickPlayer: AVAudioPlayer?
    @State private var housekeepingTimer: Timer?
    @StateObject private var tunerEngine = TunerEngine()
    @State private var preAlarmTopMode: TopClockMode?
    @State private var preAlarmUtilityMode: UtilityMode?
    @State private var showStartupScreenPicker = true
    @State private var availableDisplayTargets: [DisplayTarget] = []
    @State private var metronomeTimer: DispatchSourceTimer?
    @State private var seriesRootURL: URL?
    @State private var seriesVideoURLs: [URL] = []
    @State private var seriesCurrentVideoURL: URL?
    @State private var seriesPlayer = AVPlayer()
    @State private var seriesEscapeKeyMonitor: Any?
    @State private var seriesItemStatusObserver: NSKeyValueObservation?
    @State private var seriesSecurityScopeURL: URL?
    @State private var seriesTranscodeWorkItem: DispatchWorkItem?
    @State private var seriesPreparedURLs: [URL: URL] = [:]
    @State private var seriesStatusText: String?
    @State private var seriesPlayRequestID = 0
    @State private var seriesResumeVideoURL: URL?
    @State private var fullscreenDoubleClickMonitor: Any?
    @State private var ffmpegInstallInProgress = false
    @State private var ffmpegInstallAttempted = false
    @State private var pongFieldSizeLevel = 4
    @State private var pongRunning = false
    @State private var pongPlayerScore = 0
    @State private var pongCPUScore = 0
    @State private var pongBallPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var pongBallVelocity = CGVector(dx: 0.62, dy: 0.16)
    @State private var pongPlayerPaddleCenterY: CGFloat = 0.5
    @State private var pongAIPaddleCenterY: CGFloat = 0.5
    @State private var pongUpPressed = false
    @State private var pongDownPressed = false
    @State private var pongTimer: DispatchSourceTimer?
    @State private var pongKeyboardMonitor: Any?
    @State private var pongKeyboardFlagsMonitor: Any?
    @State private var arkanoidRunning = false
    @State private var arkanoidScore = 0
    @State private var arkanoidLives = 3
    @State private var arkanoidBallPosition = CGPoint(x: 0.5, y: 0.78)
    @State private var arkanoidBallVelocity = CGVector(dx: 0.58, dy: -0.62)
    @State private var arkanoidPaddleCenterX: CGFloat = 0.5
    @State private var arkanoidLeftPressed = false
    @State private var arkanoidRightPressed = false
    @State private var arkanoidBrickAlive = Array(repeating: true, count: 40)
    @State private var arkanoidTimer: DispatchSourceTimer?
    @State private var arkanoidKeyboardMonitor: Any?
    @State private var arkanoidKeyboardFlagsMonitor: Any?
    @State private var snakeRunning = false
    @State private var snakeScore = 0
    @State private var snakeGameOver = false
    @State private var snakeBoardSizeLevel = 3
    @State private var snakeDirection = CGVector(dx: 1, dy: 0)
    @State private var snakePendingDirection = CGVector(dx: 1, dy: 0)
    @State private var snakeBody = [SIMD2<Int32>(8, 6), SIMD2<Int32>(7, 6), SIMD2<Int32>(6, 6)]
    @State private var snakeFood = SIMD2<Int32>(14, 8)
    @State private var snakeLastStepTime: TimeInterval = 0
    @State private var snakeStepAccumulator: TimeInterval = 0
    @State private var snakeRenderProgress: CGFloat = 1
    @State private var snakeTimer: DispatchSourceTimer?
    @State private var snakeKeyboardMonitor: Any?
    @State private var missileRunning = false
    @State private var missileGameOver = false
    @State private var missileScore = 0
    @State private var missileWave = 1
    @State private var missileAmmo = 24
    @State private var missileSpawnedInWave = 0
    @State private var missileWaveQuota = 14
    @State private var missileSpawnAccumulator: CGFloat = 0
    @State private var missileCities = Array(repeating: true, count: 6)
    @State private var missileBases = Array(repeating: true, count: 3)
    @State private var missileEnemies: [MissileEnemy] = []
    @State private var missilePlayerRockets: [MissilePlayerRocket] = []
    @State private var missileExplosions: [MissileExplosion] = []
    @State private var missileTargetPoint = CGPoint(x: 0.5, y: 0.42)
    @State private var missileTimer: DispatchSourceTimer?
    @State private var todayInternetEvents: [ThisDayEvent] = []
    @State private var todayEventsRotationOffset = 0
    @State private var todayEventsTimer: Timer?
    @State private var todayEventsLastRefresh: Date?
    @State private var todayEventsLoading = false
    @State private var todayEventsInitialLoadCompleted = false
    @State private var musicThoughtQuotes: [MusicThoughtQuote] = []
    @State private var musicThoughtIndex = 0
    @State private var musicThoughtTimer: Timer?
    @State private var musicThoughtLoading = false
    @State private var musicThoughtLastRefresh: Date?
    @State private var raeSearchText = ""
    @State private var raeResultLines: [String] = []
    @State private var raeSearchRequestID = 0
    #endif

    var body: some View {
        GeometryReader { geometry in
            let mainClockSize = min(geometry.size.width * 0.15, geometry.size.height * 0.26)
            let secondsSize = min(geometry.size.width * 0.065, geometry.size.height * 0.11)
            let dateSize = min(geometry.size.width * 0.03, geometry.size.height * 0.047)
            let driveTitleSize = min(geometry.size.width * 0.05, geometry.size.height * 0.075)
            let topHalfHeight = geometry.size.height * 0.5
            let isTopFullscreen = splitFullscreenTarget == .top
            let isBottomFullscreen = splitFullscreenTarget == .bottom
            let topSectionHeight = isBottomFullscreen ? 0 : (isTopFullscreen ? geometry.size.height : topHalfHeight)
            let bottomSectionHeight = isTopFullscreen ? 0 : (isBottomFullscreen ? geometry.size.height : topHalfHeight)

            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.0, green: 0.08, blue: 0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    center: .center,
                    startRadius: 80,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )

                CRTScanlines()
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                if countdownAlarmActive {
                    Text("ALARMA")
                        .font(displayFont(size: min(geometry.size.width, geometry.size.height) * 0.34, weight: .bold))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                        .shadow(color: Color.white.opacity(0.85), radius: 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background(Color.black)
                        .ignoresSafeArea()
                } else {
                    if utilityMode == .series {
                        ZStack {
                            if seriesCurrentVideoURL != nil {
                                SeriesPlayerView(player: seriesPlayer)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                                    .contentShape(Rectangle())
                                    #if os(macOS)
                                    .overlay(
                                        MouseClickCatcher(
                                            onLeftClick: { playRandomSeriesVideo() },
                                            onRightClick: { stopSeriesPlaybackByUser() }
                                        )
                                    )
                                    #else
                                    .onTapGesture {
                                        playRandomSeriesVideo()
                                    }
                                    #endif
                            } else {
                                VStack(spacing: 12) {
                                    Button(action: {
                                        chooseSeriesFolder()
                                    }) {
                                        Text(L10n.seriesChooseFolder)
                                            .font(.system(size: max(18, dateSize * 1.1), weight: .semibold, design: .monospaced))
                                            .foregroundStyle(phosphorColor)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.black.opacity(0.45))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.55), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)

                                    Text(seriesFolderLabel)
                                        .font(.system(size: max(14, dateSize * 0.9), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .lineLimit(1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.35))

                                    Button(action: {
                                        startSeriesPlaybackByUser()
                                    }) {
                                        Text(L10n.start)
                                            .font(.system(size: max(18, dateSize * 1.1), weight: .semibold, design: .monospaced))
                                            .foregroundStyle(phosphorColor)
                                            .padding(.horizontal, 22)
                                            .padding(.vertical, 10)
                                            .background(Color.black.opacity(0.45))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.55), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .overlay(alignment: .bottomLeading) {
                            if let status = seriesStatusText, status.isEmpty == false {
                                Text(status)
                                    .font(.system(size: max(12, dateSize * 0.85), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .padding(.leading, 12)
                                    .padding(.bottom, 12)
                            }
                        }
                    } else {
                    VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        if topMode == .stopwatch {
                            TimelineView(.periodic(from: .now, by: 0.01)) { context in
                                let stopwatchDisplay = stopwatchDisplayValues(at: context.date)
                                HStack(alignment: .center, spacing: 16) {
                                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                                        Text(String(format: "%02d", stopwatchDisplay.minutes))
                                            .font(displayFont(size: mainClockSize, weight: .bold))
                                            .monospacedDigit()
                                            .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                                        Text(":")
                                            .font(displayFont(size: mainClockSize, weight: .bold))
                                            .monospacedDigit()
                                            .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                                            .opacity(timeSeparatorOpacity)

                                        Text(String(format: "%02d", stopwatchDisplay.seconds))
                                            .font(displayFont(size: mainClockSize, weight: .bold))
                                            .monospacedDigit()
                                            .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                                        Text(String(format: "%02d", stopwatchDisplay.centiseconds))
                                            .font(displayFont(size: secondsSize, weight: .bold))
                                            .monospacedDigit()
                                            .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                                    }
                                    .foregroundStyle(phosphorColor)

                                    VStack(spacing: 14) {
                                        Button(action: {
                                            stopwatchPrestartCountdownEnabled.toggle()
                                        }) {
                                            Text(stopwatchPreButtonTitle)
                                                .font(.system(size: max(13, dateSize * 0.88), weight: .semibold, design: .monospaced))
                                                .foregroundStyle(stopwatchPrestartCountdownEnabled ? phosphorColor : phosphorDim)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .stroke((stopwatchPrestartCountdownEnabled ? phosphorColor : phosphorDim).opacity(0.6), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(stopwatchRunning || stopwatchPrestartInProgress)
                                        countdownButton(title: stopwatchPrimaryButtonTitle, size: max(22, dateSize * 1.6), action: toggleStopwatchRunState)
                                        countdownButton(title: L10n.reset, size: max(22, dateSize * 1.6), action: resetStopwatch)
                                    }
                                    .padding(.leading, 10)
                                }
                            }
                        } else if topMode == .countdown {
                            HStack(alignment: .center, spacing: 16) {
                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text(String(format: "%02d", countdownDisplayHours))
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementCountdownHour() },
                                                onRightClick: { decrementCountdownHour() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            incrementCountdownHour()
                                        }
                                        #endif

                                    Text(":")
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                                        .opacity(timeSeparatorOpacity)

                                    Text(String(format: "%02d", countdownDisplayMinutes))
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementCountdownMinute() },
                                                onRightClick: { decrementCountdownMinute() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            incrementCountdownMinute()
                                        }
                                        #endif

                                    Text(String(format: "%02d", countdownDisplaySeconds))
                                        .font(displayFont(size: secondsSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementCountdownSecond() },
                                                onRightClick: { decrementCountdownSecond() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            incrementCountdownSecond()
                                        }
                                        #endif
                                }
                                .foregroundStyle(phosphorColor)

                                VStack(spacing: 14) {
                                    countdownButton(title: countdownPrimaryButtonTitle, size: max(22, dateSize * 1.6), action: toggleCountdownRunState)
                                    countdownButton(title: L10n.stop, size: max(22, dateSize * 1.6), action: stopCountdown)
                                    countdownButton(title: L10n.reset, size: max(22, dateSize * 1.6), action: resetCountdown)
                                }
                                .padding(.leading, 10)
                            }
                        } else if topMode == .alarm {
                            HStack(alignment: .center, spacing: 16) {
                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text(String(format: "%02d", alarmSetHours))
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: alarmColor.opacity(0.75), radius: 8)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementAlarmHour() },
                                                onRightClick: { decrementAlarmHour() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            incrementAlarmHour()
                                        }
                                        #endif

                                    Text(":")
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: alarmColor.opacity(0.75), radius: 8)
                                        .opacity(timeSeparatorOpacity)

                                    Text(String(format: "%02d", alarmSetMinutes))
                                        .font(displayFont(size: mainClockSize, weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: alarmColor.opacity(0.75), radius: 8)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementAlarmMinute() },
                                                onRightClick: { decrementAlarmMinute() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            incrementAlarmMinute()
                                        }
                                        #endif

                                }
                                .foregroundStyle(alarmColor)

                                HStack(spacing: 8) {
                                    Button(action: { alarmEnabled.toggle() }) {
                                        Text(alarmEnabled ? "ON" : "OFF")
                                            .font(.system(size: max(16, dateSize * 1.2), weight: .semibold, design: .monospaced))
                                            .foregroundStyle(alarmEnabled ? alarmColor : phosphorDim)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    Toggle("", isOn: $alarmEnabled)
                                        .labelsHidden()
                                }
                                .padding(.leading, 10)
                            }
                        } else {
                            HStack(alignment: .lastTextBaseline, spacing: 10) {
                                Text(displayedHourMinuteParts.hours)
                                    .font(displayFont(size: mainClockSize, weight: .bold))
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                                Text(":")
                                    .font(displayFont(size: mainClockSize, weight: .bold))
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                                    .opacity(timeSeparatorOpacity)

                                Text(displayedHourMinuteParts.minutes)
                                    .font(displayFont(size: mainClockSize, weight: .bold))
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                                Text(displayedSecondsText)
                                    .font(displayFont(size: secondsSize, weight: .bold))
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.7), radius: 6)

                                if topMode == .worldClock {
                                    Text(worldClockCityCode)
                                        .font(displayFont(size: max(34, dateSize * 2.05), weight: .bold))
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                                        .padding(.leading, 18)
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { rotateWorldCityForward() },
                                                onRightClick: { rotateWorldCityBackward() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            rotateWorldCityForward()
                                        }
                                        #endif
                                }
                            }
                            .foregroundStyle(phosphorColor)
                        }

                        if topMode == .clock {
                            Text(viewModel.dateText)
                                .font(displayFont(size: dateSize, weight: .medium))
                                .foregroundStyle(phosphorDim)
                                .shadow(color: phosphorColor.opacity(0.5), radius: 4)
                                .offset(y: 10)
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(height: topSectionHeight)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        if isBottomFullscreen == false {
                            HStack(spacing: 8) {
                                splitFullscreenButton(target: .top)

                                if alarmEnabled {
                                    Circle()
                                        .fill(alarmColor)
                                        .frame(width: 18, height: 18)
                                        .shadow(color: alarmColor.opacity(0.7), radius: 4)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 10)
                        }
                    }

                    if splitFullscreenTarget == .none {
                        Rectangle()
                            .fill(phosphorColor.opacity(0.18))
                            .frame(height: 1)
                    }

                    #if os(macOS)
                    Group {
                        if utilityMode == .audio {
                            VStack(spacing: 10) {
                                Text(L10n.selectedAudio)
                                    .font(.system(size: max(16, dateSize * 1.2), weight: .medium, design: .monospaced))
                                    .foregroundStyle(phosphorDim)

                                Text(selectedAudioDeviceName)
                                    .font(displayFont(size: max(22, driveTitleSize * 1.2), weight: .bold))
                                    .foregroundStyle(phosphorColor)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                                    .padding(.horizontal, 18)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .metronome {
                            HStack(alignment: .center, spacing: 18) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.06, green: 0.15, blue: 0.09))
                                    Circle()
                                        .fill(phosphorColor.opacity(metronomePulseActive ? 0.95 : 0.18))
                                        .blur(radius: metronomePulseActive ? 2.0 : 0)
                                        .animation(.easeOut(duration: 0.16), value: metronomePulseActive)
                                    Circle()
                                        .stroke(phosphorColor.opacity(0.65), lineWidth: 2)
                                }
                                .frame(width: topHalfHeight * 0.82, height: topHalfHeight * 0.82)
                                .shadow(color: phosphorColor.opacity(metronomePulseActive ? 0.55 : 0.18), radius: 12)

                                VStack(spacing: 14) {
                                    HStack(alignment: .center, spacing: 6) {
                                        Text("\(metronomeNumerator)")
                                            .font(displayFont(size: max(24, dateSize * 1.45), weight: .regular))
                                            .foregroundStyle(phosphorColor)
                                            .monospacedDigit()
                                            .contentShape(Rectangle())
                                            .overlay(
                                                MouseClickCatcher(
                                                    onLeftClick: { rotateMetronomeNumeratorForward() },
                                                    onRightClick: { rotateMetronomeNumeratorBackward() }
                                                )
                                            )

                                        Text("/")
                                            .font(displayFont(size: max(24, dateSize * 1.45), weight: .regular))
                                            .foregroundStyle(phosphorDim)

                                        Text("\(metronomeDenominator)")
                                            .font(displayFont(size: max(24, dateSize * 1.45), weight: .regular))
                                            .foregroundStyle(phosphorColor)
                                            .monospacedDigit()
                                            .contentShape(Rectangle())
                                            .overlay(
                                                MouseClickCatcher(
                                                    onLeftClick: { rotateMetronomeDenominatorForward() },
                                                    onRightClick: { rotateMetronomeDenominatorBackward() }
                                                )
                                            )
                                    }
                                    .frame(width: 190)
                                    .padding(.vertical, 9)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                                    )

                                    Text("BPM")
                                        .font(.system(size: max(15, dateSize * 1.15), weight: .medium, design: .monospaced))
                                        .foregroundStyle(phosphorDim)

                                    Text("\(metronomeBPM)")
                                        .font(displayFont(size: max(32, driveTitleSize * 1.45), weight: .bold))
                                        .foregroundStyle(phosphorColor)
                                        .monospacedDigit()
                                        .contentShape(Rectangle())
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { incrementMetronomeBPM() },
                                                onRightClick: { decrementMetronomeBPM() }
                                            )
                                        )

                                    Button(action: {
                                        if metronomeRunning {
                                            stopMetronome()
                                        } else {
                                            startMetronome()
                                        }
                                    }) {
                                        Text(metronomeRunning ? L10n.stop : L10n.start)
                                            .font(displayFont(size: max(20, dateSize * 1.45), weight: .regular))
                                            .foregroundStyle(phosphorColor)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(width: 190)
                                            .padding(.vertical, 10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(PressableCountdownButtonStyle(phosphorColor: phosphorColor))
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .tuner {
                            VStack(spacing: 14) {
                                if tunerEngine.permissionDenied {
                                    VStack(spacing: 6) {
                                        Text(L10n.tunerMicPermission)
                                            .font(.system(size: max(14, dateSize), weight: .medium, design: .monospaced))
                                            .foregroundStyle(Color.red)
                                        Button(L10n.tunerRequestPermission) {
                                            tunerEngine.requestMicrophonePermissionFromUI()
                                        }
                                        .buttonStyle(.plain)
                                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .underline()
                                    }
                                }

                                Menu {
                                    ForEach(tunerEngine.inputs) { input in
                                        Button(input.name) {
                                            tunerEngine.selectInput(input.id)
                                        }
                                    }
                                } label: {
                                    Text(tunerInputLabel)
                                        .font(.system(size: max(15, dateSize * 1.15), weight: .medium, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                                .menuStyle(.borderlessButton)

                                Menu {
                                    if tunerEngine.inputSources.isEmpty {
                                        Text(L10n.tunerNoSources)
                                    } else {
                                        ForEach(tunerEngine.inputSources) { source in
                                            Button(source.name) {
                                                tunerEngine.selectInputSource(source.id)
                                            }
                                        }
                                    }
                                } label: {
                                    Text(tunerSourceLabel)
                                        .font(.system(size: max(15, dateSize * 1.05), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .menuStyle(.borderlessButton)
                                .buttonStyle(.plain)

                                Text(tunerEngine.noteName)
                                    .font(displayFont(size: max(58, driveTitleSize * 2.4), weight: .bold))
                                    .foregroundStyle(phosphorColor)
                                    .shadow(color: phosphorColor.opacity(0.7), radius: 8)

                                VStack(spacing: 6) {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(Color(red: 0.08, green: 0.18, blue: 0.11))
                                            .frame(width: max(240, topHalfHeight * 0.75), height: 12)

                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(tunerBarColor)
                                            .frame(width: tunerBarWidth(total: max(240, topHalfHeight * 0.75)), height: 12)
                                    }

                                    Text(tunerStatusText)
                                        .font(.system(size: max(15, dateSize * 1.05), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .monospacedDigit()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .chordDetect {
                            VStack(spacing: 12) {
                                if tunerEngine.permissionDenied {
                                    VStack(spacing: 6) {
                                        Text(L10n.tunerMicPermission)
                                            .font(.system(size: max(14, dateSize), weight: .medium, design: .monospaced))
                                            .foregroundStyle(Color.red)
                                        Button(L10n.tunerRequestPermission) {
                                            tunerEngine.requestMicrophonePermissionFromUI()
                                        }
                                        .buttonStyle(.plain)
                                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .underline()
                                    }
                                }

                                Menu {
                                    ForEach(tunerEngine.inputs) { input in
                                        Button(input.name) {
                                            tunerEngine.selectInput(input.id)
                                        }
                                    }
                                } label: {
                                    Text(tunerInputLabel)
                                        .font(.system(size: max(15, dateSize * 1.15), weight: .medium, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                                .menuStyle(.borderlessButton)

                                Menu {
                                    if tunerEngine.inputSources.isEmpty {
                                        Text(L10n.tunerNoSources)
                                    } else {
                                        ForEach(tunerEngine.inputSources) { source in
                                            Button(source.name) {
                                                tunerEngine.selectInputSource(source.id)
                                            }
                                        }
                                    }
                                } label: {
                                    Text(tunerSourceLabel)
                                        .font(.system(size: max(15, dateSize * 1.05), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .lineLimit(1)
                                        .underline()
                                }
                                .menuStyle(.borderlessButton)
                                .buttonStyle(.plain)

                                Text(tunerEngine.detectedChordName)
                                    .font(displayFont(size: max(50, driveTitleSize * 2.2), weight: .bold))
                                    .foregroundStyle(phosphorColor)
                                    .shadow(color: phosphorColor.opacity(0.7), radius: 8)

                                Text(chordDetectStatusText)
                                    .font(.system(size: max(15, dateSize * 1.05), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .chordFinder {
                            ZStack {
                                if let voicing = activeChordVoicing {
                                    chordDiagram(voicing: voicing)
                                        .frame(width: min(300, topHalfHeight * 1.1), height: min(220, topHalfHeight * 0.78))
                                        .contentShape(Rectangle())
                                        #if os(macOS)
                                        .overlay(
                                            MouseClickCatcher(
                                                onLeftClick: { rotateChordVoicingForward() },
                                                onRightClick: { rotateChordVoicingBackward() }
                                            )
                                        )
                                        #else
                                        .onTapGesture {
                                            rotateChordVoicingForward()
                                        }
                                        #endif
                                } else {
                                    Text(L10n.chordFinderNoMatch)
                                        .font(displayFont(size: max(22, dateSize * 1.35), weight: .semibold))
                                        .foregroundStyle(phosphorColor)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    TextField(L10n.chordFinderPlaceholder, text: $chordInput)
                                        .font(.system(size: max(18, dateSize * 1.12), weight: .medium, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .textFieldStyle(.plain)
                                        .frame(width: 140, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.black.opacity(0.35))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                                        )
                                        .onChange(of: chordInput) { _, _ in
                                            refreshChordFinder()
                                        }

                                    Text(activeChordKeyText)
                                        .font(displayFont(size: max(24, dateSize * 1.4), weight: .bold))
                                        .foregroundStyle(phosphorDim)
                                        .lineLimit(1)

                                    if activeChordVoicing != nil {
                                        Text(chordVoicingPositionText)
                                            .font(.system(size: max(14, dateSize * 0.98), weight: .regular, design: .monospaced))
                                            .foregroundStyle(phosphorDim)
                                    }
                                }
                                .frame(width: min(280, topHalfHeight * 0.95), alignment: .leading)
                                .padding(.leading, 18)
                                .padding(.top, 34)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .pong {
                            pongView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .arkanoid {
                            arkanoidView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .missileCommand {
                            missileCommandView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .snake {
                            snakeView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .todayInHistory {
                            todayInHistoryView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .musicThought {
                            musicThoughtView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .rae {
                            raeView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .series {
                            ZStack(alignment: .topLeading) {
                                if seriesCurrentVideoURL != nil {
                                    SeriesPlayerView(player: seriesPlayer)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            playRandomSeriesVideo()
                                        }
                                } else {
                                    VStack(spacing: 8) {
                                        Text(L10n.seriesNoVideo)
                                            .font(displayFont(size: max(20, dateSize * 1.3), weight: .semibold))
                                            .foregroundStyle(phosphorColor)

                                        Text(L10n.seriesHint)
                                            .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                                            .foregroundStyle(phosphorDim)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Button(action: {
                                            chooseSeriesFolder()
                                        }) {
                                            Text(L10n.seriesChooseFolder)
                                                .font(.system(size: max(14, dateSize * 1.0), weight: .semibold, design: .monospaced))
                                                .foregroundStyle(phosphorColor)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color.black.opacity(0.45))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .stroke(phosphorColor.opacity(0.55), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)

                                        Text(seriesFolderLabel)
                                            .font(.system(size: max(13, dateSize * 0.9), weight: .regular, design: .monospaced))
                                            .foregroundStyle(phosphorDim)
                                            .lineLimit(1)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color.black.opacity(0.35))
                                    }
                                }
                                .padding(.leading, 14)
                                .padding(.top, 52)
                            }
                            .overlay(alignment: .bottomLeading) {
                                if let status = seriesStatusText, status.isEmpty == false {
                                    Text(status)
                                        .font(.system(size: max(12, dateSize * 0.85), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.45))
                                        .padding(.leading, 12)
                                        .padding(.bottom, 12)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .onAppear {
                                installSeriesEscapeKeyMonitorIfNeeded()
                            }
                            .onDisappear {
                                removeSeriesEscapeKeyMonitor()
                            }
                        } else if utilityMode == .volume {
                            VStack(spacing: 10) {
                                Text(L10n.systemVolume)
                                    .font(.system(size: max(16, dateSize * 1.2), weight: .medium, design: .monospaced))
                                    .foregroundStyle(phosphorDim)

                                if systemVolumePercent <= 0.0001 {
                                    Text("MUTED")
                                        .font(displayFont(size: max(28, driveTitleSize * 1.45), weight: .bold))
                                        .foregroundStyle(Color.red)
                                        .monospacedDigit()
                                        .shadow(color: Color.red.opacity(0.55), radius: 6)
                                } else {
                                    Text(String(format: "%.0f%%", systemVolumePercent))
                                        .font(displayFont(size: max(28, driveTitleSize * 1.45), weight: .bold))
                                        .foregroundStyle(phosphorColor)
                                        .monospacedDigit()
                                        .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .cpu {
                            VStack(spacing: 14) {
                                Text(L10n.cpuUsage)
                                    .font(.system(size: max(16, dateSize * 1.2), weight: .medium, design: .monospaced))
                                    .foregroundStyle(phosphorDim)

                                Text(String(format: "%.1f%%", cpuUsagePercent))
                                    .font(displayFont(size: max(28, driveTitleSize * 1.5), weight: .bold))
                                    .foregroundStyle(phosphorColor)
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.7), radius: 6)

                                Text(memoryUsageText)
                                    .font(displayFont(size: max(20, driveTitleSize * 1.05), weight: .regular))
                                    .foregroundStyle(phosphorDim)
                                    .monospacedDigit()
                                    .shadow(color: phosphorColor.opacity(0.45), radius: 4)
                                    .padding(.top, 18)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 64)
                        } else if utilityMode == .apps {
                            VStack(spacing: 12) {
                                if runningAppsUsage.isEmpty {
                                    Text(L10n.noRunningAppsCPUData)
                                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                } else {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        VStack(spacing: 8) {
                                            ForEach(runningAppsUsage) { app in
                                                HStack(spacing: 10) {
                                                    Image(nsImage: app.icon)
                                                        .resizable()
                                                        .interpolation(.high)
                                                        .frame(width: max(16, dateSize * 1.05), height: max(16, dateSize * 1.05))
                                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                                    Text(app.name)
                                                        .font(.system(size: max(13, dateSize * 0.95), weight: .regular, design: .monospaced))
                                                        .foregroundStyle(phosphorColor)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)

                                                    Spacer(minLength: 8)

                                                    Text(String(format: "%.1f%%", app.cpuPercent))
                                                        .font(.system(size: max(13, dateSize * 0.95), weight: .semibold, design: .monospaced))
                                                        .foregroundStyle(phosphorDim)
                                                        .monospacedDigit()
                                                }
                                                .padding(.horizontal, 12)
                                            }
                                        }
                                        .padding(.top, 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 40)
                        } else if utilityMode == .processes {
                            VStack(spacing: 12) {
                                if runningProcessesUsage.isEmpty {
                                    Text(L10n.noRunningProcessesCPUData)
                                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                } else {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        VStack(spacing: 8) {
                                            ForEach(runningProcessesUsage) { process in
                                                HStack(spacing: 10) {
                                                    Text("\(process.id)")
                                                        .font(.system(size: max(12, dateSize * 0.85), weight: .regular, design: .monospaced))
                                                        .foregroundStyle(phosphorDim)
                                                        .frame(width: max(44, dateSize * 2.6), alignment: .leading)
                                                        .lineLimit(1)

                                                    Text(process.name)
                                                        .font(.system(size: max(13, dateSize * 0.95), weight: .regular, design: .monospaced))
                                                        .foregroundStyle(phosphorColor)
                                                        .lineLimit(1)
                                                        .truncationMode(.middle)

                                                    Spacer(minLength: 8)

                                                    Text(String(format: "%.1f%%", process.cpuPercent))
                                                        .font(.system(size: max(13, dateSize * 0.95), weight: .semibold, design: .monospaced))
                                                        .foregroundStyle(phosphorDim)
                                                        .monospacedDigit()
                                                }
                                                .padding(.horizontal, 12)
                                            }
                                        }
                                        .padding(.top, 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 40)
                        } else if utilityMode == .storage {
                            utilityVolumesList(
                                usbMonitor.storageVolumes,
                                rowFontSize: driveTitleSize,
                                topInset: 56,
                                fixedNameWidth: driveTitleSize * 5.6
                            )
                        } else {
                            utilityVolumesList(
                                usbMonitor.volumes,
                                rowFontSize: driveTitleSize,
                                topInset: 56,
                                fixedNameWidth: nil
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(height: bottomSectionHeight)
                    .clipped()
                    .background(Color(red: 0.08, green: 0.18, blue: 0.11).opacity(0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0, style: .continuous)
                            .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isTopFullscreen == false {
                            splitFullscreenButton(target: .bottom)
                                .padding(.top, 8)
                                .padding(.trailing, 10)
                        }
                    }
                    .overlay {
                        if utilityMode == .volume {
                            MouseScrollCatcher { deltaY in
                                adjustSystemVolumeFromScroll(deltaY: deltaY)
                            }
                        }
                    }
                    #endif
                    }
                    }
                }

                #if os(macOS)
                Color.white
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                #endif

                if stopwatchPrestartInProgress, let displayValue = stopwatchPrestartDisplayValue {
                    Text("\(displayValue)")
                        .font(displayFont(size: min(geometry.size.width, geometry.size.height) * 0.78, weight: .bold))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.9), radius: 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .topLeading) {
                if countdownAlarmActive == false, utilityMode != .series, isBottomFullscreen == false {
                    modeSelectorTag(
                        topModeLabel,
                        topPadding: 8,
                        onLeftClick: {
                            rotateTopMode(forward: true)
                            #if os(macOS)
                            triggerFlash()
                            #endif
                        },
                        onRightClick: {
                            rotateTopMode(forward: false)
                            #if os(macOS)
                            triggerFlash()
                            #endif
                        }
                    )
                }
            }
            .overlay(alignment: .topLeading) {
                if countdownAlarmActive == false, isTopFullscreen == false {
                    let hideUtilityTagInSeriesFullscreen = (utilityMode == .series && seriesCurrentVideoURL != nil)
                    if hideUtilityTagInSeriesFullscreen == false {
                    modeSelectorTag(
                        utilityModeLabel,
                        topPadding: topSectionHeight + 8,
                        onLeftClick: {
                            rotateUtilityMode(forward: true)
                            #if os(macOS)
                            triggerFlash()
                            #endif
                        },
                        onRightClick: {
                            rotateUtilityMode(forward: false)
                            #if os(macOS)
                            triggerFlash()
                            #endif
                        }
                    )
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if countdownAlarmActive == false {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(phosphorColor)
                            .padding(12)
                            .background(Color.black.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 14)
                    .padding(.bottom, 14)
                }
            }
            .overlay {
                #if os(macOS)
                if showStartupScreenPicker {
                    startupScreenPickerView
                }
                #endif
                if showSettings {
                    settingsView
                }
            }
        }
        .ignoresSafeArea()
        #if os(macOS)
        .background(WindowReader(window: $hostWindow))
        .onAppear {
            clearSeriesCacheOnLaunch()
            loadModeVisibilitySettings()
            installFullscreenDoubleClickMonitorIfNeeded()
            knownVolumeIDs = Set(usbMonitor.volumes.map(\.id))
            syncAlarmToCurrentTimeIfUnset()
            refreshAudioDeviceName()
            refreshCPUUsage()
            refreshSystemAudioState(triggerOnMuteTransition: false)
            startHousekeepingTimer()
            refreshAvailableDisplays()
            applySavedStartupDisplaySelectionIfNeeded()
            if utilityMode == .tuner || utilityMode == .chordDetect {
                tunerEngine.refreshInputs()
                tunerEngine.start()
            } else if utilityMode == .chordFinder {
                refreshChordFinder()
            } else if utilityMode == .pong {
                activatePongMode()
            } else if utilityMode == .arkanoid {
                activateArkanoidMode()
            } else if utilityMode == .missileCommand {
                activateMissileCommandMode()
            } else if utilityMode == .snake {
                activateSnakeMode()
            } else if utilityMode == .todayInHistory {
                activateTodayInHistoryMode()
            } else if utilityMode == .musicThought {
                activateMusicThoughtMode()
            }
        }
        .onChange(of: usbMonitor.volumes.map(\.id)) { _, ids in
            let newIDs = Set(ids)
            let addedIDs = newIDs.subtracting(knownVolumeIDs)
            if newIDs != knownVolumeIDs {
                triggerFlash()
            }
            if addedIDs.isEmpty == false {
                if enabledUtilityModes.contains(.usb) {
                    utilityMode = .usb
                }
            }
            knownVolumeIDs = newIDs
        }
        .onChange(of: viewModel.now) { _, _ in
            tickCountdown()
            tickScheduledAlarm(now: viewModel.now)
        }
        .onChange(of: utilityMode) { _, newMode in
            if newMode == .tuner || newMode == .chordDetect {
                tunerEngine.refreshInputs()
                tunerEngine.start()
            } else {
                tunerEngine.stop()
            }

            if newMode == .chordFinder {
                refreshChordFinder()
            }

            if newMode == .series {
                seriesStatusText = nil
            } else {
                seriesPlayer.pause()
                removeSeriesEscapeKeyMonitor()
            }

            if newMode == .pong {
                activatePongMode()
            } else {
                deactivatePongMode()
            }

            if newMode == .arkanoid {
                activateArkanoidMode()
            } else {
                deactivateArkanoidMode()
            }

            if newMode == .missileCommand {
                activateMissileCommandMode()
            } else {
                deactivateMissileCommandMode()
            }

            if newMode == .snake {
                activateSnakeMode()
            } else {
                deactivateSnakeMode()
            }

            if newMode == .todayInHistory {
                activateTodayInHistoryMode()
            } else {
                deactivateTodayInHistoryMode()
            }

            if newMode == .musicThought {
                activateMusicThoughtMode()
            } else {
                deactivateMusicThoughtMode()
            }

        }
        .simultaneousGesture(
            TapGesture().onEnded {
                stopCountdownAlarmIfNeeded(restorePreviousModes: true)
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { notification in
            guard let window = notification.object as? NSWindow, window == hostWindow else { return }
            preferredFullscreen = true
            saveModeVisibilitySettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { notification in
            guard let window = notification.object as? NSWindow, window == hostWindow else { return }
            preferredFullscreen = false
            saveModeVisibilitySettings()
        }
        .onDisappear {
            cancelStopwatchPrestartCountdown()
            stopMetronome()
            tunerEngine.stop()
            deactivatePongMode()
            deactivateArkanoidMode()
            deactivateMissileCommandMode()
            deactivateSnakeMode()
            deactivateTodayInHistoryMode()
            deactivateMusicThoughtMode()
            seriesPlayer.pause()
            seriesTranscodeWorkItem?.cancel()
            seriesTranscodeWorkItem = nil
            removeSeriesEscapeKeyMonitor()
            releaseSeriesSecurityScope()
            removeFullscreenDoubleClickMonitor()
            stopHousekeepingTimer()
        }
        #endif
    }

    private func displayFont(size: CGFloat, weight: Font.Weight) -> Font {
        #if os(macOS)
        let boldWeights: [Font.Weight] = [.bold, .semibold, .heavy, .black]
        let dsegBold = "DSEG14Modern-Bold"
        let dsegRegular = "DSEG14Modern-Regular"

        if boldWeights.contains(weight), NSFont(name: dsegBold, size: size) != nil {
            return .custom(dsegBold, size: size)
        }

        if NSFont(name: dsegRegular, size: size) != nil {
            return .custom(dsegRegular, size: size)
        }

        if boldWeights.contains(weight), NSFont(name: "DSEG7ClassicMini-Bold", size: size) != nil {
            return .custom("DSEG7ClassicMini-Bold", size: size)
        }
        if NSFont(name: "DSEG7Classic-Regular", size: size) != nil {
            return .custom("DSEG7Classic-Regular", size: size)
        }

        return .custom("Menlo", size: size)
        #else
        return .system(size: size, weight: weight, design: .monospaced)
        #endif
    }

    private var phosphorColor: Color {
        displayPalette.color
    }

    private var phosphorDim: Color {
        displayPalette.dimColor
    }

    private var alarmColor: Color {
        phosphorColor
    }

    private var tunerBelowColor: Color {
        Color(red: 1.0, green: 0.88, blue: 0.2)
    }

    private var displayedHourMinuteText: String {
        switch topMode {
        case .clock:
            return viewModel.hourMinuteText
        case .worldClock:
            return worldClockHourMinuteText
        case .uptime:
            return uptimeText.hourMinute
        case .stopwatch:
            return stopwatchText.hourMinute
        case .countdown:
            return countdownText.hourMinute
        case .alarm:
            return String(format: "%02d:%02d", alarmSetHours, alarmSetMinutes)
        }
    }

    private var displayedHourMinuteParts: (hours: String, minutes: String) {
        let text = displayedHourMinuteText
        guard let separator = text.firstIndex(of: ":") else {
            return (text, "00")
        }
        let hours = String(text[..<separator])
        let minutesStart = text.index(after: separator)
        let minutes = String(text[minutesStart...])
        return (hours, minutes)
    }

    private var shouldBlinkTimeSeparator: Bool {
        switch topMode {
        case .clock, .worldClock, .uptime:
            return true
        case .stopwatch:
            return stopwatchRunning
        case .countdown:
            return countdownRunning
        case .alarm:
            return false
        }
    }

    private var timeSeparatorOpacity: Double {
        guard shouldBlinkTimeSeparator else { return 1.0 }
        let second = Calendar.current.component(.second, from: viewModel.now)
        return second.isMultiple(of: 2) ? 1.0 : 0.18
    }

    private var topModeLabel: String {
        topModeLabel(for: topMode)
    }

    private var utilityModeLabel: String {
        utilityModeLabel(for: utilityMode)
    }

    private func topModeLabel(for mode: TopClockMode) -> String {
        switch mode {
        case .clock:
            return L10n.modeClock
        case .worldClock:
            return L10n.modeWorldClock
        case .uptime:
            return L10n.modeAwake
        case .stopwatch:
            return L10n.modeStopwatch
        case .countdown:
            return L10n.modeCountdown
        case .alarm:
            return L10n.modeAlarm
        }
    }

    private func utilityModeLabel(for mode: UtilityMode) -> String {
        switch mode {
        case .usb:
            return L10n.modeUSB
        case .audio:
            return L10n.modeAudio
        case .storage:
            return L10n.modeStorage
        case .cpu:
            return L10n.modeCPU
        case .apps:
            return L10n.modeApps
        case .processes:
            return L10n.modeProcesses
        case .volume:
            return L10n.modeVolume
        case .metronome:
            return L10n.modeMetronome
        case .tuner:
            return L10n.modeTuner
        case .chordDetect:
            return L10n.modeChordDetect
        case .chordFinder:
            return L10n.modeChordFinder
        case .pong:
            return L10n.modePong
        case .arkanoid:
            return L10n.modeArkanoid
        case .missileCommand:
            return L10n.modeMissileCommand
        case .snake:
            return L10n.modeSnake
        case .todayInHistory:
            return L10n.modeTodayInHistory
        case .musicThought:
            return L10n.modeMusicThought
        case .rae:
            return L10n.modeRAE
        case .series:
            return L10n.modeSeries
        }
    }

    private var seriesFolderLabel: String {
        if let name = seriesRootURL?.lastPathComponent, name.isEmpty == false {
            return name
        }
        return L10n.seriesNoFolder
    }

    private var tunerInputLabel: String {
        if let selected = tunerEngine.inputs.first(where: { $0.id == tunerEngine.selectedInputID }) {
            return selected.name
        }
        return L10n.tunerSelectInput
    }

    private var tunerSourceLabel: String {
        if let selected = tunerEngine.inputSources.first(where: { $0.id == tunerEngine.selectedInputSourceID }) {
            return selected.name
        }
        return L10n.tunerSelectSource
    }

    private var tunerClampedCents: Double {
        max(-50, min(50, tunerEngine.cents))
    }

    private func tunerBarWidth(total: CGFloat) -> CGFloat {
        let ratio = CGFloat((tunerClampedCents + 50) / 100)
        return max(6, total * ratio)
    }

    private var tunerBarColor: Color {
        if abs(tunerEngine.cents) <= 5, tunerEngine.frequency > 0 {
            return Color.green
        }
        if tunerEngine.cents > 0, tunerEngine.frequency > 0 {
            return Color.red
        }
        return tunerBelowColor
    }

    private var tunerStatusText: String {
        if tunerEngine.frequency <= 0 {
            return L10n.tunerNoSignal
        }
        return String(format: "%.1f Hz  %+0.1f¢", tunerEngine.frequency, tunerEngine.cents)
    }

    private var chordDetectStatusText: String {
        if tunerEngine.detectedChordName == "--" {
            return L10n.tunerNoSignal
        }
        let confidence = Int((tunerEngine.detectedChordConfidence * 100).rounded())
        let notes = tunerEngine.detectedChordNotes.isEmpty ? "--" : tunerEngine.detectedChordNotes.joined(separator: " ")
        return "conf \(confidence)%  \(notes)"
    }

    private var activeChordKeyText: String {
        parsedChord?.symbol ?? "--"
    }

    private var chordVoicings: [ChordVoicing] {
        chordGeneratedVoicings
    }

    private var activeChordVoicing: ChordVoicing? {
        guard chordVoicings.isEmpty == false else { return nil }
        let index = min(max(chordVoicingIndex, 0), chordVoicings.count - 1)
        return chordVoicings[index]
    }

    private var chordVoicingPositionText: String {
        guard chordVoicings.isEmpty == false else { return "0/0" }
        let current = min(max(chordVoicingIndex, 0), chordVoicings.count - 1) + 1
        return "\(current)/\(chordVoicings.count)"
    }

    private func rotateChordVoicingForward() {
        guard chordVoicings.isEmpty == false else { return }
        chordVoicingIndex = (chordVoicingIndex + 1) % chordVoicings.count
    }

    private func rotateChordVoicingBackward() {
        guard chordVoicings.isEmpty == false else { return }
        chordVoicingIndex = (chordVoicingIndex - 1 + chordVoicings.count) % chordVoicings.count
    }

    private func refreshChordFinder() {
        chordVoicingIndex = 0
        parsedChord = parseChord(from: chordInput)
        guard let parsedChord else {
            chordGeneratedVoicings = []
            return
        }
        let preferred = preferredChordVoicings(for: parsedChord.lookupKey)
        let preferredKeys = Set(preferred.map { $0.frets.map(String.init).joined(separator: ",") })
        let generated = generateChordVoicings(for: parsedChord)
        var seen = Set<String>()
        let merged = (preferred + generated).filter { voicing in
            let key = voicing.frets.map(String.init).joined(separator: ",")
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        chordGeneratedVoicings = merged
            .filter { chordVoicingIsDisplayable($0) }
            .sorted { lhs, rhs in
                let lhsKey = lhs.frets.map(String.init).joined(separator: ",")
                let rhsKey = rhs.frets.map(String.init).joined(separator: ",")
                let lhsPreferred = preferredKeys.contains(lhsKey)
                let rhsPreferred = preferredKeys.contains(rhsKey)
                if lhsPreferred != rhsPreferred { return lhsPreferred && !rhsPreferred }
                let lhsScore = chordVoicingScore(lhs)
                let rhsScore = chordVoicingScore(rhs)
                if lhsScore != rhsScore { return lhsScore < rhsScore }
                return lhs.id < rhs.id
            }
            .prefix(4)
            .map { $0 }
    }

    private func parseChord(from raw: String) -> ParsedChord? {
        var text = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "♭", with: "b")
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "Δ", with: "maj")
            .replacingOccurrences(of: " ", with: "")
        guard text.isEmpty == false else { return nil }

        if let slash = text.firstIndex(of: "/") {
            text = String(text[..<slash])
        }

        let chars = Array(text)
        guard let first = chars.first else { return nil }
        let rootLetter = String(first).uppercased()
        guard ["A", "B", "C", "D", "E", "F", "G"].contains(rootLetter) else { return nil }

        var index = 1
        var accidental = ""
        if chars.count > 1, chars[1] == "#" || chars[1] == "b" {
            accidental = String(chars[1])
            index = 2
        }

        let descriptorRaw = String(chars.dropFirst(index))
        let descriptor = descriptorRaw.lowercased()
        guard let rootPitchClass = pitchClassForRoot(rootLetter + accidental) else { return nil }

        var intervals = Set<Int>()
        let hasSus2 = descriptor.contains("sus2")
        let hasSus4 = descriptor.contains("sus4") || (descriptor.contains("sus") && hasSus2 == false)
        let hasDim = descriptor.contains("dim") || descriptor.contains("o")
        let hasAug = descriptor.contains("aug") || descriptor.contains("+")
        let isMinor = (descriptor.hasPrefix("m") || descriptor.hasPrefix("min")) &&
            descriptor.hasPrefix("maj") == false &&
            descriptor.hasPrefix("ma") == false
        let isPower = descriptor == "5"

        if isPower {
            intervals.formUnion([0, 7])
        } else if hasSus2 {
            intervals.formUnion([0, 2, 7])
        } else if hasSus4 {
            intervals.formUnion([0, 5, 7])
        } else if hasDim {
            intervals.formUnion([0, 3, 6])
        } else if hasAug {
            intervals.formUnion([0, 4, 8])
        } else if isMinor {
            intervals.formUnion([0, 3, 7])
        } else {
            intervals.formUnion([0, 4, 7])
        }

        if descriptor.contains("no3") {
            intervals.remove(3)
            intervals.remove(4)
        }

        if descriptor.contains("b5") {
            intervals.remove(7)
            intervals.insert(6)
        }
        if descriptor.contains("#5") || descriptor.contains("+5") {
            intervals.remove(7)
            intervals.insert(8)
        }

        let hasMaj7 = descriptor.contains("maj7") || descriptor.contains("ma7")
        let hasAny7 = descriptor.contains("7")
        if hasMaj7 {
            intervals.insert(11)
        } else if hasAny7 {
            if hasDim && descriptor.contains("dim7") {
                intervals.insert(9)
            } else {
                intervals.insert(10)
            }
        }

        if descriptor.contains("6") && descriptor.contains("16") == false {
            intervals.insert(9)
        }
        if descriptor.contains("9") {
            intervals.insert(2)
        }
        if descriptor.contains("11") {
            intervals.insert(5)
        }
        if descriptor.contains("13") {
            intervals.insert(9)
        }

        if descriptor.contains("add2") { intervals.insert(2) }
        if descriptor.contains("add4") { intervals.insert(5) }
        if descriptor.contains("add9") { intervals.insert(2) }
        if descriptor.contains("add11") { intervals.insert(5) }
        if descriptor.contains("add13") { intervals.insert(9) }

        if descriptor.contains("b9") { intervals.insert(1) }
        if descriptor.contains("#9") { intervals.insert(3) }
        if descriptor.contains("#11") { intervals.insert(6) }
        if descriptor.contains("b13") { intervals.insert(8) }

        if intervals.isEmpty {
            intervals = [0, 4, 7]
        }

        let pitchClasses = Set(intervals.map { (rootPitchClass + $0 + 120) % 12 })
        let lookupSuffix: String
        if hasSus2 { lookupSuffix = "sus2" }
        else if hasSus4 { lookupSuffix = "sus4" }
        else if hasDim { lookupSuffix = "dim" }
        else if hasAug { lookupSuffix = "aug" }
        else if hasMaj7 { lookupSuffix = "maj7" }
        else if descriptor.contains("m7") || descriptor.contains("min7") || descriptor.contains("minor7") { lookupSuffix = "m7" }
        else if hasAny7 { lookupSuffix = "7" }
        else if isMinor { lookupSuffix = "m" }
        else { lookupSuffix = "" }

        let symbol = rootLetter + accidental + descriptorRaw
        let lookupKey = rootLetter + accidental + lookupSuffix
        return ParsedChord(symbol: symbol, lookupKey: lookupKey, rootPitchClass: rootPitchClass, pitchClasses: pitchClasses)
    }

    private func preferredChordVoicings(for key: String) -> [ChordVoicing] {
        let base: [String: [ChordVoicing]] = [
            "C": [
                ChordVoicing(id: "C_open", frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]),
                ChordVoicing(id: "C_barre_3", frets: [-1, 3, 5, 5, 5, 3], fingers: [0, 1, 3, 4, 2, 1])
            ],
            "Cm": [
                ChordVoicing(id: "Cm_barre_3", frets: [-1, 3, 5, 5, 4, 3], fingers: [0, 1, 3, 4, 2, 1]),
                ChordVoicing(id: "Cm_barre_8", frets: [8, 10, 10, 8, 8, 8], fingers: [1, 3, 4, 1, 1, 1])
            ],
            "C7": [
                ChordVoicing(id: "C7_open", frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0])
            ],
            "Cmaj7": [
                ChordVoicing(id: "Cmaj7_open", frets: [-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0])
            ],
            "D": [
                ChordVoicing(id: "D_open", frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]),
                ChordVoicing(id: "D_barre_5", frets: [-1, 5, 7, 7, 7, 5], fingers: [0, 1, 3, 4, 2, 1])
            ],
            "Dm": [
                ChordVoicing(id: "Dm_open", frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1])
            ],
            "D7": [
                ChordVoicing(id: "D7_open", frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3])
            ],
            "E": [
                ChordVoicing(id: "E_open", frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]),
                ChordVoicing(id: "E_barre_12", frets: [12, 14, 14, 13, 12, 12], fingers: [1, 3, 4, 2, 1, 1])
            ],
            "Em": [
                ChordVoicing(id: "Em_open", frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0]),
                ChordVoicing(id: "Em_barre_7", frets: [7, 7, 9, 9, 8, 7], fingers: [1, 1, 3, 4, 2, 1])
            ],
            "E7": [
                ChordVoicing(id: "E7_open", frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0])
            ],
            "F": [
                ChordVoicing(id: "F_barre_1", frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1]),
                ChordVoicing(id: "F_small", frets: [-1, -1, 3, 2, 1, 1], fingers: [0, 0, 4, 3, 1, 2])
            ],
            "Fm": [
                ChordVoicing(id: "Fm_barre_1", frets: [1, 3, 3, 1, 1, 1], fingers: [1, 3, 4, 1, 1, 1])
            ],
            "G": [
                ChordVoicing(id: "G_open", frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3]),
                ChordVoicing(id: "G_barre_3", frets: [3, 5, 5, 4, 3, 3], fingers: [1, 3, 4, 2, 1, 1])
            ],
            "G7": [
                ChordVoicing(id: "G7_open", frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1])
            ],
            "A": [
                ChordVoicing(id: "A_open", frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0]),
                ChordVoicing(id: "A_barre_5", frets: [5, 7, 7, 6, 5, 5], fingers: [1, 3, 4, 2, 1, 1])
            ],
            "Am": [
                ChordVoicing(id: "Am_open", frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]),
                ChordVoicing(id: "Am_barre_5", frets: [5, 7, 7, 5, 5, 5], fingers: [1, 3, 4, 1, 1, 1])
            ],
            "A7": [
                ChordVoicing(id: "A7_open", frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 2, 0, 3, 0])
            ],
            "B": [
                ChordVoicing(id: "B_barre_2", frets: [-1, 2, 4, 4, 4, 2], fingers: [0, 1, 3, 4, 2, 1])
            ],
            "Bm": [
                ChordVoicing(id: "Bm_barre_2", frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1])
            ],
            "B7": [
                ChordVoicing(id: "B7_open", frets: [-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4])
            ]
        ]
        return base[key] ?? []
    }

    private func pitchClassForRoot(_ root: String) -> Int? {
        switch root {
        case "C": return 0
        case "B#": return 0
        case "C#", "Db": return 1
        case "D": return 2
        case "D#", "Eb": return 3
        case "E", "Fb": return 4
        case "F", "E#": return 5
        case "F#", "Gb": return 6
        case "G": return 7
        case "G#", "Ab": return 8
        case "A": return 9
        case "A#", "Bb": return 10
        case "B", "Cb": return 11
        default: return nil
        }
    }

    private func generateChordVoicings(for chord: ParsedChord) -> [ChordVoicing] {
        let tuningPitchClasses = [4, 9, 2, 7, 11, 4] // E A D G B E
        let maxFret = 14

        let perStringCandidates: [[Int]] = tuningPitchClasses.map { openPC in
            var values = [-1]
            for fret in 0...maxFret {
                let noteClass = (openPC + fret) % 12
                if chord.pitchClasses.contains(noteClass) {
                    values.append(fret)
                }
            }
            return Array(values.prefix(5))
        }

        var results: [ChordVoicing] = []

        func search(
            _ stringIndex: Int,
            _ currentFrets: [Int],
            _ minFret: Int,
            _ maxChosenFret: Int,
            _ soundedCount: Int,
            _ containsRoot: Bool
        ) {
            if stringIndex == 6 {
                guard soundedCount >= 3, containsRoot else { return }
                let fretted = currentFrets.filter { $0 > 0 }
                if fretted.isEmpty == false {
                    let span = (fretted.max() ?? 0) - (fretted.min() ?? 0)
                    if span > 4 { return }
                }
                let fingers = assignFingers(for: currentFrets)
                let id = currentFrets.map(String.init).joined(separator: "-")
                results.append(ChordVoicing(id: id, frets: currentFrets, fingers: fingers))
                return
            }

            for fret in perStringCandidates[stringIndex] {
                let nextFrets = currentFrets + [fret]
                let nextSounded = soundedCount + (fret >= 0 ? 1 : 0)
                let nextMin: Int
                let nextMax: Int
                if fret > 0 {
                    nextMin = min(minFret, fret)
                    nextMax = max(maxChosenFret, fret)
                    if nextMax - nextMin > 4 { continue }
                } else {
                    nextMin = minFret
                    nextMax = maxChosenFret
                }

                var nextContainsRoot = containsRoot
                if fret >= 0 {
                    let noteClass = (tuningPitchClasses[stringIndex] + fret) % 12
                    if noteClass == chord.rootPitchClass {
                        nextContainsRoot = true
                    }
                }

                search(stringIndex + 1, nextFrets, nextMin, nextMax, nextSounded, nextContainsRoot)
            }
        }

        search(0, [], 99, 0, 0, false)

        var seen = Set<String>()
        let unique = results.filter { voicing in
            let key = voicing.frets.map(String.init).joined(separator: ",")
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        return unique
            .sorted { chordVoicingScore($0) < chordVoicingScore($1) }
            .prefix(18)
            .map { $0 }
    }

    private func chordVoicingIsDisplayable(_ voicing: ChordVoicing) -> Bool {
        let fretted = voicing.frets.filter { $0 > 0 }
        let muted = voicing.frets.filter { $0 < 0 }.count
        let sounded = voicing.frets.filter { $0 >= 0 }.count
        guard sounded >= 3 else { return false }
        if muted > 3 { return false }
        if let maxFret = fretted.max(), maxFret > 12 { return false }
        if fretted.isEmpty == false {
            let span = (fretted.max() ?? 0) - (fretted.min() ?? 0)
            if span > 4 { return false }
        }
        return true
    }

    private func chordVoicingScore(_ voicing: ChordVoicing) -> Double {
        let fretted = voicing.frets.filter { $0 > 0 }
        let muted = voicing.frets.filter { $0 < 0 }.count
        let open = voicing.frets.filter { $0 == 0 }.count
        let maxFret = fretted.max() ?? 0
        let minFret = fretted.min() ?? 0
        let span = fretted.isEmpty ? 0 : (maxFret - minFret)
        return Double(maxFret) + (Double(span) * 1.8) + (Double(muted) * 0.7) - (Double(open) * 0.2)
    }

    private func assignFingers(for frets: [Int]) -> [Int] {
        let uniqueFrets = Array(Set(frets.filter { $0 > 0 })).sorted()
        var map: [Int: Int] = [:]
        for (index, fret) in uniqueFrets.enumerated() {
            map[fret] = min(4, index + 1)
        }
        return frets.map { fret in
            guard fret > 0 else { return 0 }
            return map[fret] ?? 0
        }
    }

    @ViewBuilder
    private func chordDiagram(voicing: ChordVoicing) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let topArea = height * 0.19
            let leftInset = width * 0.13
            let rightInset = width * 0.12
            let bottomInset = height * 0.1
            let strings: CGFloat = 6
            let fretSteps: CGFloat = 5
            let gridWidth = width - leftInset - rightInset
            let gridHeight = height - topArea - bottomInset
            let stringSpacing = gridWidth / (strings - 1)
            let fretSpacing = gridHeight / fretSteps
            let pressedFrets = voicing.frets.filter { $0 > 0 }
            let minPressed = pressedFrets.min() ?? 1
            let baseFret = minPressed <= 1 ? 1 : minPressed
            let dotRadius = min(stringSpacing, fretSpacing) * 0.26

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.2))

                Path { path in
                    for i in 0..<Int(strings) {
                        let x = leftInset + CGFloat(i) * stringSpacing
                        path.move(to: CGPoint(x: x, y: topArea))
                        path.addLine(to: CGPoint(x: x, y: topArea + gridHeight))
                    }
                    for j in 0...Int(fretSteps) {
                        let y = topArea + CGFloat(j) * fretSpacing
                        path.move(to: CGPoint(x: leftInset, y: y))
                        path.addLine(to: CGPoint(x: leftInset + gridWidth, y: y))
                    }
                }
                .stroke(phosphorDim.opacity(0.82), lineWidth: 1.2)

                Path { path in
                    let nutY = topArea
                    path.move(to: CGPoint(x: leftInset, y: nutY))
                    path.addLine(to: CGPoint(x: leftInset + gridWidth, y: nutY))
                }
                .stroke(phosphorColor.opacity(0.92), lineWidth: baseFret == 1 ? 4 : 1.6)

                if baseFret > 1 {
                    Text("\(baseFret)")
                        .font(.system(size: max(11, height * 0.072), weight: .semibold, design: .monospaced))
                        .foregroundStyle(phosphorColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                        )
                        .position(x: leftInset * 0.43, y: topArea + fretSpacing * 0.55)
                }

                ForEach(0..<6, id: \.self) { stringIndex in
                    let x = leftInset + CGFloat(stringIndex) * stringSpacing
                    let fret = stringIndex < voicing.frets.count ? voicing.frets[stringIndex] : -1
                    let finger = stringIndex < voicing.fingers.count ? voicing.fingers[stringIndex] : 0

                    if fret < 0 {
                        Text("x")
                            .font(.system(size: max(12, height * 0.09), weight: .bold, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                            .position(x: x, y: topArea * 0.45)
                    } else if fret == 0 {
                        Circle()
                            .stroke(phosphorColor.opacity(0.9), lineWidth: 1.6)
                            .frame(width: dotRadius * 1.5, height: dotRadius * 1.5)
                            .position(x: x, y: topArea * 0.45)
                    } else {
                        let fretIndex = fret - baseFret + 1
                        if fretIndex >= 1 && fretIndex <= 5 {
                            let y = topArea + (CGFloat(fretIndex) - 0.5) * fretSpacing
                            Circle()
                                .fill(phosphorColor.opacity(0.92))
                                .frame(width: dotRadius * 2, height: dotRadius * 2)
                                .position(x: x, y: y)
                                .shadow(color: phosphorColor.opacity(0.45), radius: 2)

                            if finger > 0 {
                                Text("\(finger)")
                                    .font(.system(size: max(10, dotRadius * 0.95), weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.black.opacity(0.82))
                                    .position(x: x, y: y)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(phosphorColor.opacity(0.42), lineWidth: 1)
        )
    }

    private var settingsView: some View {
        ZStack {
            Color.black.opacity(0.96)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Configuracion / Settings")
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(phosphorColor)
                    Spacer()
                    Button(action: { showSettings = false }) {
                        Text("X")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Display color")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        HStack(spacing: 10) {
                            ForEach(DisplayPalette.allCases, id: \.self) { palette in
                                Button(action: {
                                    displayPalette = palette
                                    saveModeVisibilitySettings()
                                }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(palette.color)
                                            .frame(width: 12, height: 12)
                                        Text(palette.label)
                                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                                            .foregroundStyle(phosphorColor)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color.black.opacity(displayPalette == palette ? 0.65 : 0.35))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(displayPalette == palette ? 0.9 : 0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        Text("Pantalla guardada al iniciar: \(savedStartupDisplayDescription)")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        Button(action: forgetSavedStartupDisplaySelection) {
                            Text("Olvidar pantalla seleccionada al iniciar")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(phosphorColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.45))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.55), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        Text("Modo de ventana / Window mode")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        HStack(spacing: 10) {
                            Button(action: { setPreferredFullscreen(true) }) {
                                Text("Pantalla completa")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(preferredFullscreen ? 0.65 : 0.35))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(preferredFullscreen ? 0.9 : 0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: { setPreferredFullscreen(false) }) {
                                Text("Ventana")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(preferredFullscreen ? 0.35 : 0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(preferredFullscreen ? 0.4 : 0.9), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        Text("Pantalla superior / Top screen")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Text("El primero activo sera el modo por defecto")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        VStack(spacing: 7) {
                            ForEach(topModeOrder, id: \.self) { mode in
                                HStack(spacing: 10) {
                                    Text("≡")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .onDrag {
                                            draggedTopMode = mode
                                            return NSItemProvider(object: NSString(string: mode.key))
                                        }
                                    Button(action: {
                                        setTopMode(mode, enabled: enabledTopModes.contains(mode) == false)
                                    }) {
                                        Image(systemName: enabledTopModes.contains(mode) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(enabledTopModes.contains(mode) ? phosphorColor : phosphorDim)
                                    }
                                    .buttonStyle(.plain)
                                    Text(topModeLabel(for: mode))
                                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                )
                                .onDrop(of: [UTType.text], delegate: TopModeDropDelegate(
                                    target: mode,
                                    items: $topModeOrder,
                                    draggedItem: $draggedTopMode,
                                    onReorder: { saveModeVisibilitySettings() }
                                ))
                            }
                        }

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        Text("Pantalla inferior / Bottom screen")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Text("El primero activo sera el modo por defecto")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        VStack(spacing: 7) {
                            ForEach(utilityModeOrder.filter { $0 != .series }, id: \.self) { mode in
                                HStack(spacing: 12) {
                                    Text("≡")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .frame(width: 18, alignment: .center)
                                        .onDrag {
                                            draggedUtilityMode = mode
                                            return NSItemProvider(object: NSString(string: mode.key))
                                        }
                                    Button(action: {
                                        setUtilityMode(mode, enabled: enabledUtilityModes.contains(mode) == false)
                                    }) {
                                        Image(systemName: enabledUtilityModes.contains(mode) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(enabledUtilityModes.contains(mode) ? phosphorColor : phosphorDim)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 22, alignment: .center)
                                    Text(utilityModeLabel(for: mode))
                                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .frame(width: 210, alignment: .leading)

                                    Spacer(minLength: 0)

                                    if mode == .pong {
                                        Text("size \(pongFieldSizeLevel)")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(phosphorDim)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.35))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                                            )
                                            #if os(macOS)
                                            .overlay(
                                                MouseClickCatcher(
                                                    onLeftClick: { rotatePongFieldSize(forward: true) },
                                                    onRightClick: { rotatePongFieldSize(forward: false) }
                                                )
                                            )
                                            #else
                                            .onTapGesture {
                                                rotatePongFieldSize(forward: true)
                                            }
                                            #endif
                                    }

                                    if mode == .snake {
                                        Text("size \(snakeBoardSizeLevel)")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(phosphorDim)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.35))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                                            )
                                            #if os(macOS)
                                            .overlay(
                                                MouseClickCatcher(
                                                    onLeftClick: { rotateSnakeBoardSize(forward: true) },
                                                    onRightClick: { rotateSnakeBoardSize(forward: false) }
                                                )
                                            )
                                            #else
                                            .onTapGesture {
                                                rotateSnakeBoardSize(forward: true)
                                            }
                                            #endif
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                )
                                .onDrop(of: [UTType.text], delegate: UtilityModeDropDelegate(
                                    target: mode,
                                    items: $utilityModeOrder,
                                    draggedItem: $draggedUtilityMode,
                                    onReorder: { saveModeVisibilitySettings() }
                                ))
                            }
                        }

                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                showQuitAppConfirmation = true
                            } label: {
                                Text(L10n.quitApp)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.red.opacity(0.9))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.red.opacity(0.55), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 26)
                }
            }
        }
        .alert(L10n.quitAppTitle, isPresented: $showQuitAppConfirmation) {
            Button(L10n.cancel, role: .cancel) { }
            Button(L10n.quit, role: .destructive) {
                #if os(macOS)
                NSApp.terminate(nil)
                #endif
            }
        } message: {
            Text(L10n.quitAppConfirmationMessage)
        }
    }

    private func topModeToggleBinding(for mode: TopClockMode) -> Binding<Bool> {
        Binding(
            get: { enabledTopModes.contains(mode) },
            set: { setTopMode(mode, enabled: $0) }
        )
    }

    private func utilityModeToggleBinding(for mode: UtilityMode) -> Binding<Bool> {
        Binding(
            get: { enabledUtilityModes.contains(mode) },
            set: { setUtilityMode(mode, enabled: $0) }
        )
    }

    private func setTopMode(_ mode: TopClockMode, enabled: Bool) {
        if enabled {
            enabledTopModes.insert(mode)
        } else if enabledTopModes.count > 1 {
            enabledTopModes.remove(mode)
        }
        if enabledTopModes.contains(topMode) == false, let fallback = orderedEnabledTopModes().first {
            topMode = fallback
        }
        saveModeVisibilitySettings()
    }

    private func setUtilityMode(_ mode: UtilityMode, enabled: Bool) {
        guard mode != .series else { return }
        if enabled {
            enabledUtilityModes.insert(mode)
        } else if enabledUtilityModes.count > 1 {
            enabledUtilityModes.remove(mode)
        }
        if enabledUtilityModes.contains(utilityMode) == false, let fallback = orderedEnabledUtilityModes().first {
            utilityMode = fallback
            handleUtilityModeActivation(fallback)
        }
        saveModeVisibilitySettings()
    }

    private func orderedEnabledTopModes() -> [TopClockMode] {
        let modes = topModeOrder.filter { enabledTopModes.contains($0) }
        return modes.isEmpty ? TopClockMode.allCases : modes
    }

    private var availableUtilityModes: [UtilityMode] {
        UtilityMode.allCases.filter { $0 != .series }
    }

    private func orderedEnabledUtilityModes() -> [UtilityMode] {
        let modes = utilityModeOrder.filter { enabledUtilityModes.contains($0) && $0 != .series }
        return modes.isEmpty ? availableUtilityModes : modes
    }

    private func moveTopMode(_ mode: TopClockMode, up: Bool) {
        guard let index = topModeOrder.firstIndex(of: mode) else { return }
        let target = up ? index - 1 : index + 1
        guard topModeOrder.indices.contains(target) else { return }
        topModeOrder.swapAt(index, target)
        saveModeVisibilitySettings()
    }

    private func moveUtilityMode(_ mode: UtilityMode, up: Bool) {
        guard let index = utilityModeOrder.firstIndex(of: mode) else { return }
        let target = up ? index - 1 : index + 1
        guard utilityModeOrder.indices.contains(target) else { return }
        utilityModeOrder.swapAt(index, target)
        saveModeVisibilitySettings()
    }

    private func moveTopModes(from source: IndexSet, to destination: Int) {
        topModeOrder.move(fromOffsets: source, toOffset: destination)
        saveModeVisibilitySettings()
    }

    private func moveUtilityModes(from source: IndexSet, to destination: Int) {
        var filtered = utilityModeOrder.filter { $0 != .series }
        filtered.move(fromOffsets: source, toOffset: destination)
        let hasSeries = utilityModeOrder.contains(.series)
        utilityModeOrder = hasSeries ? (filtered + [.series]) : filtered
        saveModeVisibilitySettings()
    }

    private func rotateTopMode(forward: Bool) {
        let modes = orderedEnabledTopModes()
        guard let currentIndex = modes.firstIndex(of: topMode) else {
            topMode = modes.first ?? .clock
            return
        }
        let nextIndex = forward
            ? (currentIndex + 1) % modes.count
            : (currentIndex - 1 + modes.count) % modes.count
        topMode = modes[nextIndex]
    }

    private func rotateUtilityMode(forward: Bool) {
        let modes = orderedEnabledUtilityModes()
        guard let currentIndex = modes.firstIndex(of: utilityMode) else {
            let fallback = modes.first ?? .audio
            utilityMode = fallback
            handleUtilityModeActivation(fallback)
            return
        }
        let nextIndex = forward
            ? (currentIndex + 1) % modes.count
            : (currentIndex - 1 + modes.count) % modes.count
        let nextMode = modes[nextIndex]
        utilityMode = nextMode
        handleUtilityModeActivation(nextMode)
    }

    private func handleUtilityModeActivation(_ mode: UtilityMode) {
        if mode == .audio {
            refreshAudioDeviceName()
        } else if mode == .cpu {
            refreshCPUUsage()
        } else if mode == .apps {
            refreshRunningAppsUsage()
        } else if mode == .processes {
            refreshRunningProcessesUsage()
        } else if mode == .volume {
            refreshSystemAudioState(triggerOnMuteTransition: false)
        } else if mode == .tuner || mode == .chordDetect {
            tunerEngine.refreshInputs()
            tunerEngine.start()
        } else if mode == .chordFinder {
            refreshChordFinder()
        }
    }

    private func loadModeVisibilitySettings() {
        let defaults = UserDefaults.standard

        if let paletteRaw = defaults.string(forKey: "utilclock.displayPalette"),
           let savedPalette = DisplayPalette(rawValue: paletteRaw) {
            displayPalette = savedPalette
        }

        if let storedTop = defaults.array(forKey: "utilclock.enabledTopModes") as? [String] {
            let restored = Set(TopClockMode.allCases.filter { storedTop.contains($0.key) })
            if restored.isEmpty == false {
                enabledTopModes = restored
            }
        }

        if let storedUtility = defaults.array(forKey: "utilclock.enabledUtilityModes") as? [String] {
            let restored = Set(availableUtilityModes.filter { storedUtility.contains($0.key) })
            if restored.isEmpty == false {
                enabledUtilityModes = restored
            }
        }

        if let storedTopOrder = defaults.array(forKey: "utilclock.topModeOrder") as? [String] {
            let restoredOrder = storedTopOrder.compactMap { key in
                TopClockMode.allCases.first(where: { $0.key == key })
            }
            let missing = TopClockMode.allCases.filter { restoredOrder.contains($0) == false }
            let merged = restoredOrder + missing
            if merged.isEmpty == false {
                topModeOrder = merged
            }
        }

        if let storedUtilityOrder = defaults.array(forKey: "utilclock.utilityModeOrder") as? [String] {
            let restoredOrder = storedUtilityOrder.compactMap { key in
                availableUtilityModes.first(where: { $0.key == key })
            }
            let missing = availableUtilityModes.filter { restoredOrder.contains($0) == false }
            let merged = restoredOrder + missing
            if merged.isEmpty == false {
                utilityModeOrder = merged
            }
        }

        if defaults.object(forKey: preferredFullscreenKey) != nil {
            preferredFullscreen = defaults.bool(forKey: preferredFullscreenKey)
        } else {
            preferredFullscreen = true
        }

        enabledUtilityModes = Set(enabledUtilityModes.filter { $0 != .series })
        utilityModeOrder = utilityModeOrder.filter { $0 != .series }
        if utilityMode == .series {
            utilityMode = .audio
        }

        let savedPongFieldSize = defaults.integer(forKey: "utilclock.pongFieldSizeLevel")
        if savedPongFieldSize >= 1, savedPongFieldSize <= 4 {
            pongFieldSizeLevel = savedPongFieldSize
        } else {
            pongFieldSizeLevel = 4
        }

        let savedSnakeBoardSize = defaults.integer(forKey: "utilclock.snakeBoardSizeLevel")
        if savedSnakeBoardSize >= 1, savedSnakeBoardSize <= 4 {
            snakeBoardSizeLevel = savedSnakeBoardSize
        } else {
            snakeBoardSizeLevel = 3
        }

        if enabledTopModes.contains(topMode) == false, let first = orderedEnabledTopModes().first {
            topMode = first
        } else if let first = orderedEnabledTopModes().first {
            topMode = first
        }
        if enabledUtilityModes.contains(utilityMode) == false, let first = orderedEnabledUtilityModes().first {
            utilityMode = first
        } else if let first = orderedEnabledUtilityModes().first {
            utilityMode = first
        }
    }

    private func saveModeVisibilitySettings() {
        let defaults = UserDefaults.standard
        defaults.set(displayPalette.rawValue, forKey: "utilclock.displayPalette")
        defaults.set(orderedEnabledTopModes().map(\.key), forKey: "utilclock.enabledTopModes")
        defaults.set(orderedEnabledUtilityModes().map(\.key), forKey: "utilclock.enabledUtilityModes")
        defaults.set(topModeOrder.map(\.key), forKey: "utilclock.topModeOrder")
        defaults.set(utilityModeOrder.filter { $0 != .series }.map(\.key), forKey: "utilclock.utilityModeOrder")
        defaults.set(max(1, min(4, pongFieldSizeLevel)), forKey: "utilclock.pongFieldSizeLevel")
        defaults.set(max(1, min(4, snakeBoardSizeLevel)), forKey: "utilclock.snakeBoardSizeLevel")
        defaults.set(preferredFullscreen, forKey: preferredFullscreenKey)
    }

    private func rotatePongFieldSize(forward: Bool) {
        let current = max(1, min(4, pongFieldSizeLevel))
        if forward {
            pongFieldSizeLevel = current == 4 ? 1 : current + 1
        } else {
            pongFieldSizeLevel = current == 1 ? 4 : current - 1
        }
        saveModeVisibilitySettings()
    }

    private func rotateSnakeBoardSize(forward: Bool) {
        let current = max(1, min(4, snakeBoardSizeLevel))
        if forward {
            snakeBoardSizeLevel = current == 4 ? 1 : current + 1
        } else {
            snakeBoardSizeLevel = current == 1 ? 4 : current - 1
        }
        resetSnakeGame()
        saveModeVisibilitySettings()
    }

    private func toggleSplitFullscreen(_ target: SplitFullscreenTarget) {
        if splitFullscreenTarget == target {
            splitFullscreenTarget = .none
        } else {
            splitFullscreenTarget = target
        }
    }

    private func splitFullscreenIcon(for target: SplitFullscreenTarget) -> String {
        splitFullscreenTarget == target
            ? "arrow.down.right.and.arrow.up.left"
            : "arrow.up.left.and.arrow.down.right"
    }

    private func splitFullscreenButton(target: SplitFullscreenTarget) -> some View {
        Button(action: { toggleSplitFullscreen(target) }) {
            Image(systemName: splitFullscreenIcon(for: target))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(phosphorColor)
                .padding(8)
                .background(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func modeSelectorTag(
        _ text: String,
        topPadding: CGFloat,
        onLeftClick: @escaping () -> Void,
        onRightClick: @escaping () -> Void
    ) -> some View {
        Button(action: onLeftClick) {
            Text(text)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundStyle(phosphorDim)
                .frame(width: 250, height: 40, alignment: .leading)
                .padding(.leading, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .overlay(
            MouseClickCatcher(
                onLeftClick: onLeftClick,
                onRightClick: onRightClick
            )
        )
        #endif
        .offset(y: topPadding)
    }

    #if os(macOS)
    private var startupScreenPickerView: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Selecciona pantalla")
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundStyle(phosphorColor)

                Text("Choose display")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim)

                VStack(spacing: 10) {
                    ForEach(availableDisplayTargets) { target in
                        Button(action: {
                            moveToDisplayAndApplyPresentation(target.id)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(target.name)
                                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                    Text(target.resolutionText + (target.isMain ? " · principal/main" : ""))
                                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.08, green: 0.18, blue: 0.11).opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 640)
            }
            .padding(24)
        }
    }
    #endif

    @ViewBuilder
    private func utilityVolumesList(
        _ volumes: [USBVolumeInfo],
        rowFontSize: CGFloat,
        topInset: CGFloat,
        fixedNameWidth: CGFloat?
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(volumes) { volume in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(phosphorColor)
                            .font(displayFont(size: rowFontSize, weight: .semibold))
                            .frame(width: rowFontSize * 1.1)
                            .shadow(color: phosphorColor.opacity(0.6), radius: 4)

                        HStack(spacing: 10) {
                            Text(volume.label)
                                .font(
                                    displayFont(
                                        size: fixedNameWidth == nil ? rowFontSize : rowFontSize * 0.62,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(phosphorColor)
                                .lineLimit(1)
                                .frame(width: fixedNameWidth, alignment: .leading)
                                .shadow(color: phosphorColor.opacity(0.5), radius: 3)

                            DiskPieChart(
                                usedBytes: max(0, volume.totalBytes - volume.freeBytes),
                                freeBytes: max(0, volume.freeBytes)
                            )
                            .frame(width: rowFontSize, height: rowFontSize)

                            Text("\(volume.totalCompactText)/\(volume.freeCompactText)")
                                .font(displayFont(size: rowFontSize, weight: .regular))
                                .foregroundStyle(phosphorDim)
                                .lineLimit(1)
                                .shadow(color: phosphorColor.opacity(0.35), radius: 2)

                            Text(volume.fileSystem)
                                .font(
                                    displayFont(
                                        size: fixedNameWidth == nil ? rowFontSize : rowFontSize * 0.56,
                                        weight: .regular
                                    )
                                )
                                .foregroundStyle(phosphorDim)
                                .lineLimit(1)
                                .padding(.leading, 10)
                                .shadow(color: phosphorColor.opacity(0.4), radius: 2)
                        }
                        .minimumScaleFactor(0.7)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, topInset)
            .padding(.bottom, 12)
        }
    }

    #if os(macOS)
    private var pongFieldWidthScale: CGFloat {
        switch pongFieldSizeLevel {
        case 1: return 0.52
        case 2: return 0.68
        case 3: return 0.84
        default: return 1.0
        }
    }

    private var pongView: some View {
        GeometryReader { geometry in
            let paddleWidthRatio: CGFloat = 0.018
            let paddleHeightRatio: CGFloat = 0.22
            let ballRadiusRatio: CGFloat = 0.02

            let width = geometry.size.width * pongFieldWidthScale
            let height = geometry.size.height
            let paddleWidth = width * paddleWidthRatio
            let paddleHeight = height * paddleHeightRatio
            let paddleInsetX = width * 0.055
            let leftPaddleX = paddleInsetX
            let rightPaddleX = width - paddleInsetX
            let leftPaddleY = height * max(paddleHeightRatio * 0.5, min(1 - (paddleHeightRatio * 0.5), pongPlayerPaddleCenterY))
            let rightPaddleY = height * max(paddleHeightRatio * 0.5, min(1 - (paddleHeightRatio * 0.5), pongAIPaddleCenterY))
            let ballRadius = min(width, height) * ballRadiusRatio
            let ballX = width * max(ballRadiusRatio, min(1 - ballRadiusRatio, pongBallPosition.x))
            let ballY = height * max(ballRadiusRatio, min(1 - ballRadiusRatio, pongBallPosition.y))

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                Rectangle()
                    .fill(phosphorColor.opacity(0.24))
                    .frame(width: 1)

                Circle()
                    .fill(phosphorColor)
                    .frame(width: ballRadius * 2, height: ballRadius * 2)
                    .position(x: ballX, y: ballY)
                    .shadow(color: phosphorColor.opacity(0.8), radius: 5)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(phosphorColor)
                    .frame(width: paddleWidth, height: paddleHeight)
                    .position(x: leftPaddleX, y: leftPaddleY)
                    .shadow(color: phosphorColor.opacity(0.6), radius: 4)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(phosphorColor.opacity(0.9))
                    .frame(width: paddleWidth, height: paddleHeight)
                    .position(x: rightPaddleX, y: rightPaddleY)
                    .shadow(color: phosphorColor.opacity(0.6), radius: 4)

                VStack(spacing: 4) {
                    Text("PONG  \(pongPlayerScore):\(pongCPUScore)")
                        .font(displayFont(size: max(21, height * 0.09), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(pongRunning ? "RUN" : "STOP")
                        .font(.system(size: max(12, height * 0.05), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("↑/↓ mueve · → start · ← reset")
                    .font(.system(size: max(11, height * 0.043), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { startPong() },
                    onRightClick: { resetPongGame() }
                )
            )
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func activatePongMode() {
        installPongKeyboardMonitorsIfNeeded()
        startPongLoopIfNeeded()
    }

    private func deactivatePongMode() {
        pongUpPressed = false
        pongDownPressed = false
        pongTimer?.setEventHandler {}
        pongTimer?.cancel()
        pongTimer = nil
        removePongKeyboardMonitors()
    }

    private func startPongLoopIfNeeded() {
        guard pongTimer == nil else { return }
        var lastTick = CACurrentMediaTime()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            let now = CACurrentMediaTime()
            let delta = max(1.0 / 240.0, min(1.0 / 25.0, now - lastTick))
            lastTick = now
            DispatchQueue.main.async {
                updatePongFrame(deltaTime: CGFloat(delta))
            }
        }
        timer.resume()
        pongTimer = timer
    }

    private func installPongKeyboardMonitorsIfNeeded() {
        if pongKeyboardMonitor == nil {
            pongKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard utilityMode == .pong else { return event }
                switch event.keyCode {
                case 126: // up
                    pongUpPressed = true
                    return nil
                case 125: // down
                    pongDownPressed = true
                    return nil
                case 124: // right
                    startPong()
                    return nil
                case 123: // left
                    resetPongGame()
                    return nil
                default:
                    return event
                }
            }
        }

        if pongKeyboardFlagsMonitor == nil {
            pongKeyboardFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
                guard utilityMode == .pong else { return event }
                switch event.keyCode {
                case 126:
                    pongUpPressed = false
                    return nil
                case 125:
                    pongDownPressed = false
                    return nil
                default:
                    return event
                }
            }
        }
    }

    private func removePongKeyboardMonitors() {
        if let monitor = pongKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            pongKeyboardMonitor = nil
        }
        if let monitor = pongKeyboardFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            pongKeyboardFlagsMonitor = nil
        }
    }

    private func startPong() {
        pongRunning = true
    }

    private func resetPongGame() {
        pongRunning = false
        pongPlayerScore = 0
        pongCPUScore = 0
        pongPlayerPaddleCenterY = 0.5
        pongAIPaddleCenterY = 0.5
        resetPongServe(towardsRight: Bool.random())
    }

    private func resetPongServe(towardsRight: Bool) {
        let horizontalDirection: CGFloat = towardsRight ? 1 : -1
        let randomY = CGFloat.random(in: -0.22...0.22)
        pongBallPosition = CGPoint(x: 0.5, y: 0.5)
        pongBallVelocity = CGVector(dx: 0.62 * horizontalDirection, dy: randomY)
    }

    private func updatePongFrame(deltaTime dt: CGFloat) {
        guard utilityMode == .pong else { return }
        let paddleSpeed: CGFloat = 0.95
        let aiPaddleSpeed: CGFloat = 0.46
        let paddleHalfHeight: CGFloat = 0.11
        let paddleX: CGFloat = 0.055
        let rightPaddleX: CGFloat = 1 - paddleX
        let paddleWidth: CGFloat = 0.018
        let ballRadius: CGFloat = 0.02

        if pongUpPressed {
            pongPlayerPaddleCenterY -= paddleSpeed * dt
        }
        if pongDownPressed {
            pongPlayerPaddleCenterY += paddleSpeed * dt
        }
        pongPlayerPaddleCenterY = max(paddleHalfHeight, min(1 - paddleHalfHeight, pongPlayerPaddleCenterY))

        // Easier AI: slower reaction, larger dead zone, and intentional tracking offset.
        let aiDeadZone: CGFloat = 0.04
        let aiBias = sin(viewModel.now.timeIntervalSinceReferenceDate * 1.1) * 0.05
        let aiTargetY = max(paddleHalfHeight, min(1 - paddleHalfHeight, pongBallPosition.y + aiBias))
        let aiDelta = aiTargetY - pongAIPaddleCenterY
        if abs(aiDelta) > aiDeadZone {
            let dir: CGFloat = aiDelta > 0 ? 1 : -1
            pongAIPaddleCenterY += dir * aiPaddleSpeed * dt
            pongAIPaddleCenterY = max(paddleHalfHeight, min(1 - paddleHalfHeight, pongAIPaddleCenterY))
        }

        guard pongRunning else { return }

        var nextX = pongBallPosition.x + (pongBallVelocity.dx * dt)
        var nextY = pongBallPosition.y + (pongBallVelocity.dy * dt)
        var nextDX = pongBallVelocity.dx
        var nextDY = pongBallVelocity.dy

        if nextY <= ballRadius {
            nextY = ballRadius
            nextDY = abs(nextDY)
        } else if nextY >= (1 - ballRadius) {
            nextY = 1 - ballRadius
            nextDY = -abs(nextDY)
        }

        let leftMinY = pongPlayerPaddleCenterY - paddleHalfHeight
        let leftMaxY = pongPlayerPaddleCenterY + paddleHalfHeight
        if nextDX < 0,
           nextX - ballRadius <= (paddleX + (paddleWidth * 0.5)),
           nextX + ballRadius >= (paddleX - (paddleWidth * 0.5)),
           nextY >= leftMinY,
           nextY <= leftMaxY {
            let relative = (nextY - pongPlayerPaddleCenterY) / paddleHalfHeight
            let clamped = max(-1, min(1, relative))
            let speed = min(1.3, hypot(nextDX, nextDY) * 1.03 + 0.01)
            nextDX = abs(speed)
            nextDY = speed * clamped * 0.72
            nextX = paddleX + (paddleWidth * 0.5) + ballRadius + 0.001
        }

        let rightMinY = pongAIPaddleCenterY - paddleHalfHeight
        let rightMaxY = pongAIPaddleCenterY + paddleHalfHeight
        if nextDX > 0,
           nextX + ballRadius >= (rightPaddleX - (paddleWidth * 0.5)),
           nextX - ballRadius <= (rightPaddleX + (paddleWidth * 0.5)),
           nextY >= rightMinY,
           nextY <= rightMaxY {
            let relative = (nextY - pongAIPaddleCenterY) / paddleHalfHeight
            let clamped = max(-1, min(1, relative))
            let speed = min(1.3, hypot(nextDX, nextDY) * 1.03 + 0.01)
            nextDX = -abs(speed)
            nextDY = speed * clamped * 0.72
            nextX = rightPaddleX - (paddleWidth * 0.5) - ballRadius - 0.001
        }

        if nextX < -ballRadius {
            pongCPUScore += 1
            triggerFlash()
            resetPongServe(towardsRight: true)
            return
        }

        if nextX > 1 + ballRadius {
            pongPlayerScore += 1
            triggerFlash()
            resetPongServe(towardsRight: false)
            return
        }

        pongBallPosition = CGPoint(x: nextX, y: nextY)
        pongBallVelocity = CGVector(dx: nextDX, dy: nextDY)
    }

    private var arkanoidColumns: Int { 8 }
    private var arkanoidRows: Int { 5 }

    private var arkanoidView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height
            let paddleWidth = width * 0.2
            let paddleHeight = height * 0.025
            let paddleY = height * 0.9
            let paddleX = width * max(0.12, min(0.88, arkanoidPaddleCenterX))
            let ballRadius = min(width, height) * 0.018
            let ballX = width * arkanoidBallPosition.x
            let ballY = height * arkanoidBallPosition.y

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(0..<(arkanoidRows * arkanoidColumns), id: \.self) { index in
                    if index < arkanoidBrickAlive.count, arkanoidBrickAlive[index] {
                        let rect = arkanoidBrickRect(index: index)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(phosphorColor.opacity(0.85))
                            .frame(width: width * rect.width, height: height * rect.height)
                            .position(x: width * (rect.midX), y: height * (rect.midY))
                            .shadow(color: phosphorColor.opacity(0.4), radius: 2)
                    }
                }

                Circle()
                    .fill(phosphorColor)
                    .frame(width: ballRadius * 2, height: ballRadius * 2)
                    .position(x: ballX, y: ballY)
                    .shadow(color: phosphorColor.opacity(0.8), radius: 5)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(phosphorColor)
                    .frame(width: paddleWidth, height: paddleHeight)
                    .position(x: paddleX, y: paddleY)
                    .shadow(color: phosphorColor.opacity(0.6), radius: 4)

                VStack(spacing: 4) {
                    Text("ARKANOID  \(arkanoidScore)")
                        .font(displayFont(size: max(20, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text("LIVES \(arkanoidLives) · \(arkanoidRunning ? "RUN" : "STOP")")
                        .font(.system(size: max(12, height * 0.045), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("←/→ mueve · ↑ start · ↓ reset")
                    .font(.system(size: max(11, height * 0.043), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { startArkanoid() },
                    onRightClick: { resetArkanoidGame() }
                )
            )
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func activateArkanoidMode() {
        if arkanoidBrickAlive.count != arkanoidRows * arkanoidColumns {
            arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
        }
        installArkanoidKeyboardMonitorsIfNeeded()
        startArkanoidLoopIfNeeded()
    }

    private func deactivateArkanoidMode() {
        arkanoidLeftPressed = false
        arkanoidRightPressed = false
        arkanoidTimer?.setEventHandler {}
        arkanoidTimer?.cancel()
        arkanoidTimer = nil
        removeArkanoidKeyboardMonitors()
    }

    private func startArkanoidLoopIfNeeded() {
        guard arkanoidTimer == nil else { return }
        var lastTick = CACurrentMediaTime()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            let now = CACurrentMediaTime()
            let delta = max(1.0 / 240.0, min(1.0 / 25.0, now - lastTick))
            lastTick = now
            DispatchQueue.main.async {
                updateArkanoidFrame(deltaTime: CGFloat(delta))
            }
        }
        timer.resume()
        arkanoidTimer = timer
    }

    private func installArkanoidKeyboardMonitorsIfNeeded() {
        if arkanoidKeyboardMonitor == nil {
            arkanoidKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard utilityMode == .arkanoid else { return event }
                switch event.keyCode {
                case 123:
                    arkanoidLeftPressed = true
                    return nil
                case 124:
                    arkanoidRightPressed = true
                    return nil
                case 126:
                    startArkanoid()
                    return nil
                case 125:
                    resetArkanoidGame()
                    return nil
                default:
                    return event
                }
            }
        }

        if arkanoidKeyboardFlagsMonitor == nil {
            arkanoidKeyboardFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
                guard utilityMode == .arkanoid else { return event }
                switch event.keyCode {
                case 123:
                    arkanoidLeftPressed = false
                    return nil
                case 124:
                    arkanoidRightPressed = false
                    return nil
                default:
                    return event
                }
            }
        }
    }

    private func removeArkanoidKeyboardMonitors() {
        if let monitor = arkanoidKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            arkanoidKeyboardMonitor = nil
        }
        if let monitor = arkanoidKeyboardFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            arkanoidKeyboardFlagsMonitor = nil
        }
    }

    private func startArkanoid() {
        arkanoidRunning = true
    }

    private func resetArkanoidGame() {
        arkanoidRunning = false
        arkanoidScore = 0
        arkanoidLives = 3
        arkanoidPaddleCenterX = 0.5
        arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
        resetArkanoidServe()
    }

    private func resetArkanoidServe() {
        let randomDX = CGFloat.random(in: -0.32...0.32)
        arkanoidBallPosition = CGPoint(x: arkanoidPaddleCenterX, y: 0.78)
        arkanoidBallVelocity = CGVector(dx: randomDX, dy: -0.62)
    }

    private func arkanoidBrickRect(index: Int) -> CGRect {
        let row = index / arkanoidColumns
        let col = index % arkanoidColumns
        let horizontalInset: CGFloat = 0.06
        let topInset: CGFloat = 0.11
        let gapX: CGFloat = 0.012
        let gapY: CGFloat = 0.014
        let brickWidth = (1 - (horizontalInset * 2) - (CGFloat(arkanoidColumns - 1) * gapX)) / CGFloat(arkanoidColumns)
        let brickHeight: CGFloat = 0.048
        let x = horizontalInset + CGFloat(col) * (brickWidth + gapX)
        let y = topInset + CGFloat(row) * (brickHeight + gapY)
        return CGRect(x: x, y: y, width: brickWidth, height: brickHeight)
    }

    private func updateArkanoidFrame(deltaTime dt: CGFloat) {
        guard utilityMode == .arkanoid else { return }
        let paddleSpeed: CGFloat = 1.0
        let paddleHalfWidth: CGFloat = 0.1
        let paddleY: CGFloat = 0.9
        let paddleHeight: CGFloat = 0.025
        let ballRadius: CGFloat = 0.018

        if arkanoidLeftPressed {
            arkanoidPaddleCenterX -= paddleSpeed * dt
        }
        if arkanoidRightPressed {
            arkanoidPaddleCenterX += paddleSpeed * dt
        }
        arkanoidPaddleCenterX = max(paddleHalfWidth, min(1 - paddleHalfWidth, arkanoidPaddleCenterX))

        guard arkanoidRunning else {
            arkanoidBallPosition = CGPoint(x: arkanoidPaddleCenterX, y: 0.78)
            return
        }

        var nextX = arkanoidBallPosition.x + (arkanoidBallVelocity.dx * dt)
        var nextY = arkanoidBallPosition.y + (arkanoidBallVelocity.dy * dt)
        var nextDX = arkanoidBallVelocity.dx
        var nextDY = arkanoidBallVelocity.dy

        if nextX <= ballRadius {
            nextX = ballRadius
            nextDX = abs(nextDX)
        } else if nextX >= (1 - ballRadius) {
            nextX = 1 - ballRadius
            nextDX = -abs(nextDX)
        }

        if nextY <= ballRadius {
            nextY = ballRadius
            nextDY = abs(nextDY)
        }

        let paddleTop = paddleY - (paddleHeight * 0.5)
        let paddleMinX = arkanoidPaddleCenterX - paddleHalfWidth
        let paddleMaxX = arkanoidPaddleCenterX + paddleHalfWidth
        if nextDY > 0,
           nextY + ballRadius >= paddleTop,
           nextY - ballRadius <= paddleTop + paddleHeight,
           nextX >= paddleMinX,
           nextX <= paddleMaxX {
            let relative = (nextX - arkanoidPaddleCenterX) / paddleHalfWidth
            let clamped = max(-1, min(1, relative))
            let speed = min(1.35, hypot(nextDX, nextDY) * 1.03 + 0.01)
            nextDX = speed * clamped * 0.9
            nextDY = -sqrt(max(0.08, speed * speed - (nextDX * nextDX)))
            nextY = paddleTop - ballRadius - 0.001
        }

        let ballRect = CGRect(x: nextX - ballRadius, y: nextY - ballRadius, width: ballRadius * 2, height: ballRadius * 2)
        for index in 0..<arkanoidBrickAlive.count where arkanoidBrickAlive[index] {
            let brickRect = arkanoidBrickRect(index: index)
            if ballRect.intersects(brickRect) {
                arkanoidBrickAlive[index] = false
                arkanoidScore += 10
                let overlapLeft = abs(ballRect.maxX - brickRect.minX)
                let overlapRight = abs(brickRect.maxX - ballRect.minX)
                let overlapTop = abs(ballRect.maxY - brickRect.minY)
                let overlapBottom = abs(brickRect.maxY - ballRect.minY)
                let minOverlap = min(overlapLeft, overlapRight, overlapTop, overlapBottom)
                if minOverlap == overlapLeft || minOverlap == overlapRight {
                    nextDX = -nextDX
                } else {
                    nextDY = -nextDY
                }
                break
            }
        }

        if arkanoidBrickAlive.allSatisfy({ $0 == false }) {
            triggerFlash()
            arkanoidRunning = false
            arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
            resetArkanoidServe()
            return
        }

        if nextY - ballRadius > 1 {
            arkanoidLives -= 1
            triggerFlash()
            if arkanoidLives <= 0 {
                arkanoidRunning = false
                arkanoidLives = 3
                arkanoidScore = 0
                arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
            }
            resetArkanoidServe()
            return
        }

        arkanoidBallPosition = CGPoint(x: nextX, y: nextY)
        arkanoidBallVelocity = CGVector(dx: nextDX, dy: nextDY)
    }

    private var missileCommandView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: width, height: height)

                ForEach(0..<missileCities.count, id: \.self) { index in
                    let city = missileCityPosition(index: index)
                    if missileCities[index] {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(phosphorColor.opacity(0.9))
                            .frame(width: width * 0.065, height: height * 0.028)
                            .position(x: width * city.x, y: height * city.y)
                    }
                }

                ForEach(0..<missileBases.count, id: \.self) { index in
                    let base = missileBasePosition(index: index)
                    Path { path in
                        let x = width * base.x
                        let y = height * base.y
                        let w = width * 0.08
                        let h = height * 0.05
                        path.move(to: CGPoint(x: x, y: y - h * 0.5))
                        path.addLine(to: CGPoint(x: x - w * 0.5, y: y + h * 0.5))
                        path.addLine(to: CGPoint(x: x + w * 0.5, y: y + h * 0.5))
                        path.closeSubpath()
                    }
                    .fill(missileBases[index] ? phosphorColor : Color.red.opacity(0.55))
                }

                ForEach(missileEnemies) { missile in
                    Path { path in
                        path.move(to: CGPoint(x: width * missile.start.x, y: height * missile.start.y))
                        path.addLine(to: CGPoint(x: width * missile.position.x, y: height * missile.position.y))
                    }
                    .stroke(Color.red.opacity(0.95), lineWidth: 1.2)

                    Circle()
                        .fill(Color.red.opacity(0.95))
                        .frame(width: 5, height: 5)
                        .position(x: width * missile.position.x, y: height * missile.position.y)
                }

                ForEach(missilePlayerRockets) { rocket in
                    Path { path in
                        path.move(to: CGPoint(x: width * rocket.start.x, y: height * rocket.start.y))
                        path.addLine(to: CGPoint(x: width * rocket.position.x, y: height * rocket.position.y))
                    }
                    .stroke(phosphorColor.opacity(0.95), lineWidth: 1.2)

                    Circle()
                        .fill(phosphorColor)
                        .frame(width: 4, height: 4)
                        .position(x: width * rocket.position.x, y: height * rocket.position.y)
                }

                ForEach(missileExplosions) { explosion in
                    Circle()
                        .stroke(phosphorColor.opacity(0.95), lineWidth: 2)
                        .frame(
                            width: width * missileExplosionRadius(explosion) * 2,
                            height: height * missileExplosionRadius(explosion) * 2
                        )
                        .position(x: width * explosion.center.x, y: height * explosion.center.y)
                }

                Path { path in
                    let x = width * missileTargetPoint.x
                    let y = height * missileTargetPoint.y
                    path.move(to: CGPoint(x: x - 9, y: y))
                    path.addLine(to: CGPoint(x: x + 9, y: y))
                    path.move(to: CGPoint(x: x, y: y - 9))
                    path.addLine(to: CGPoint(x: x, y: y + 9))
                }
                .stroke(phosphorColor.opacity(0.85), lineWidth: 1.1)

                VStack(spacing: 4) {
                    Text("MISSILE COMMAND  \(missileScore)")
                        .font(displayFont(size: max(20, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text("W\(missileWave) · AMMO \(missileAmmo) · \(missileGameOver ? "GAME OVER" : (missileRunning ? "RUN" : "READY"))")
                        .font(.system(size: max(12, height * 0.045), weight: .regular, design: .monospaced))
                        .foregroundStyle(missileGameOver ? Color.red : phosphorDim)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("raton: mover mira · click der dispara · izq reset")
                    .font(.system(size: max(11, height * 0.041), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseTrackingCatcher(
                    onMove: { point in
                        missileTargetPoint = normalizeMissileInput(point, width: width, height: height)
                    },
                    onLeftClick: { point in
                        let normalized = normalizeMissileInput(point, width: width, height: height)
                        missileTargetPoint = normalized
                        if missileGameOver {
                            resetMissileCommandGame()
                        }
                    },
                    onRightClick: { point in
                        let normalized = normalizeMissileInput(point, width: width, height: height)
                        missileCommandFire(at: normalized)
                    }
                )
            )
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func activateMissileCommandMode() {
        if missileCities.count != 6 || missileBases.count != 3 {
            resetMissileCommandGame()
        }
        startMissileCommandLoopIfNeeded()
    }

    private func deactivateMissileCommandMode() {
        missileTimer?.setEventHandler {}
        missileTimer?.cancel()
        missileTimer = nil
    }

    private func startMissileCommandLoopIfNeeded() {
        guard missileTimer == nil else { return }
        var lastTick = CACurrentMediaTime()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            let now = CACurrentMediaTime()
            let delta = max(1.0 / 240.0, min(1.0 / 20.0, now - lastTick))
            lastTick = now
            DispatchQueue.main.async {
                updateMissileCommandFrame(deltaTime: CGFloat(delta))
            }
        }
        timer.resume()
        missileTimer = timer
    }

    private func resetMissileCommandGame() {
        missileRunning = false
        missileGameOver = false
        missileScore = 0
        missileWave = 1
        missileAmmo = 24
        missileSpawnedInWave = 0
        missileWaveQuota = 14
        missileSpawnAccumulator = 0
        missileCities = Array(repeating: true, count: 6)
        missileBases = Array(repeating: true, count: 3)
        missileEnemies = []
        missilePlayerRockets = []
        missileExplosions = []
        missileTargetPoint = CGPoint(x: 0.5, y: 0.42)
    }

    private func missileCommandFire(at point: CGPoint) {
        missileTargetPoint = point

        if missileGameOver {
            resetMissileCommandGame()
            missileRunning = true
            return
        }

        if missileRunning == false {
            missileRunning = true
        }

        guard missileAmmo > 0 else { return }
        guard let baseIndex = nearestAliveMissileBase(to: point) else { return }

        let start = missileBasePosition(index: baseIndex)
        let vector = CGVector(dx: point.x - start.x, dy: point.y - start.y)
        let length = max(0.0001, sqrt((vector.dx * vector.dx) + (vector.dy * vector.dy)))
        let speed: CGFloat = 0.74
        let velocity = CGVector(dx: vector.dx / length * speed, dy: vector.dy / length * speed)
        missilePlayerRockets.append(
            MissilePlayerRocket(
                start: start,
                target: point,
                position: start,
                velocity: velocity
            )
        )
        missileAmmo -= 1
    }

    private func updateMissileCommandFrame(deltaTime dt: CGFloat) {
        guard utilityMode == .missileCommand else { return }
        guard missileGameOver == false else { return }
        guard missileRunning else { return }

        let spawnInterval = max(0.34, 1.28 - CGFloat(missileWave - 1) * 0.045)
        missileSpawnAccumulator += dt
        while missileSpawnAccumulator >= spawnInterval, missileSpawnedInWave < missileWaveQuota {
            missileSpawnAccumulator -= spawnInterval
            spawnMissileEnemy()
        }

        var nextRockets: [MissilePlayerRocket] = []
        nextRockets.reserveCapacity(missilePlayerRockets.count)
        for var rocket in missilePlayerRockets {
            rocket.position.x += rocket.velocity.dx * dt
            rocket.position.y += rocket.velocity.dy * dt
            let dx = rocket.target.x - rocket.position.x
            let dy = rocket.target.y - rocket.position.y
            if (dx * dx + dy * dy) <= 0.00045 {
                missileExplosions.append(MissileExplosion(center: rocket.target, age: 0, maxAge: 0.8, maxRadius: 0.10))
            } else {
                nextRockets.append(rocket)
            }
        }
        missilePlayerRockets = nextRockets

        var nextExplosions: [MissileExplosion] = []
        nextExplosions.reserveCapacity(missileExplosions.count)
        for var explosion in missileExplosions {
            explosion.age += dt
            if explosion.age <= explosion.maxAge {
                nextExplosions.append(explosion)
            }
        }
        missileExplosions = nextExplosions

        var impactedTargets: [MissileTargetKind] = []
        var movingEnemies: [MissileEnemy] = []
        movingEnemies.reserveCapacity(missileEnemies.count)
        for var enemy in missileEnemies {
            enemy.position.x += enemy.velocity.dx * dt
            enemy.position.y += enemy.velocity.dy * dt
            let dx = enemy.target.x - enemy.position.x
            let dy = enemy.target.y - enemy.position.y
            if (dx * dx + dy * dy) <= 0.00032 || enemy.position.y >= enemy.target.y {
                impactedTargets.append(enemy.targetKind)
                missileExplosions.append(MissileExplosion(center: enemy.target, age: 0, maxAge: 0.55, maxRadius: 0.07))
            } else {
                movingEnemies.append(enemy)
            }
        }
        missileEnemies = movingEnemies

        for target in impactedTargets {
            switch target {
            case .city(let index):
                if missileCities.indices.contains(index) {
                    missileCities[index] = false
                }
            case .base(let index):
                if missileBases.indices.contains(index) {
                    missileBases[index] = false
                }
            }
        }

        let explosionSpheres: [(center: CGPoint, radius: CGFloat)] = missileExplosions.map {
            ($0.center, missileExplosionRadius($0))
        }
        var destroyedEnemyIDs = Set<UUID>()
        for enemy in missileEnemies {
            for explosion in explosionSpheres {
                let dx = enemy.position.x - explosion.center.x
                let dy = enemy.position.y - explosion.center.y
                if (dx * dx + dy * dy) <= (explosion.radius * explosion.radius) {
                    destroyedEnemyIDs.insert(enemy.id)
                    missileScore += 25
                    missileExplosions.append(
                        MissileExplosion(center: enemy.position, age: 0, maxAge: 0.45, maxRadius: 0.06)
                    )
                    break
                }
            }
        }
        if destroyedEnemyIDs.isEmpty == false {
            missileEnemies.removeAll { destroyedEnemyIDs.contains($0.id) }
        }

        if missileCities.contains(true) == false && missileBases.contains(true) == false {
            missileGameOver = true
            missileRunning = false
            triggerFlash()
            return
        }

        let waveCleared = missileSpawnedInWave >= missileWaveQuota &&
            missileEnemies.isEmpty &&
            missilePlayerRockets.isEmpty
        if waveCleared {
            missileWave += 1
            missileAmmo = min(40, missileAmmo + 14)
            missileWaveQuota = min(44, missileWaveQuota + 4)
            missileSpawnedInWave = 0
            missileSpawnAccumulator = 0
            triggerFlash()
        }
    }

    private func spawnMissileEnemy() {
        guard let target = randomMissileTarget() else { return }

        let start = CGPoint(x: CGFloat.random(in: 0.04...0.96), y: 0.02)
        let vector = CGVector(dx: target.point.x - start.x, dy: target.point.y - start.y)
        let length = max(0.0001, sqrt((vector.dx * vector.dx) + (vector.dy * vector.dy)))
        let speed: CGFloat = min(0.27, 0.07 + CGFloat(missileWave) * 0.012 + CGFloat.random(in: 0...0.03))
        let velocity = CGVector(dx: vector.dx / length * speed, dy: vector.dy / length * speed)
        missileEnemies.append(
            MissileEnemy(
                start: start,
                target: target.point,
                targetKind: target.kind,
                position: start,
                velocity: velocity
            )
        )
        missileSpawnedInWave += 1
    }

    private func normalizeMissileInput(_ point: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        let normalizedX = max(0, min(1, point.x / max(1, width)))
        // NSEvent reports Y from bottom-left; game coordinates are top-left.
        let normalizedYTop = 1 - (point.y / max(1, height))
        return CGPoint(
            x: normalizedX,
            y: max(0.05, min(0.92, normalizedYTop))
        )
    }

    private func nearestAliveMissileBase(to point: CGPoint) -> Int? {
        let aliveBases = missileBases.indices.filter { missileBases[$0] }
        guard aliveBases.isEmpty == false else { return nil }
        return aliveBases.min(by: { lhs, rhs in
            let a = missileBasePosition(index: lhs)
            let b = missileBasePosition(index: rhs)
            let da = (a.x - point.x) * (a.x - point.x) + (a.y - point.y) * (a.y - point.y)
            let db = (b.x - point.x) * (b.x - point.x) + (b.y - point.y) * (b.y - point.y)
            return da < db
        })
    }

    private func randomMissileTarget() -> (point: CGPoint, kind: MissileTargetKind)? {
        var options: [(CGPoint, MissileTargetKind)] = []
        for index in missileCities.indices where missileCities[index] {
            options.append((missileCityPosition(index: index), .city(index)))
        }
        for index in missileBases.indices where missileBases[index] {
            options.append((missileBasePosition(index: index), .base(index)))
        }
        guard options.isEmpty == false else { return nil }
        return options.randomElement()
    }

    private func missileExplosionRadius(_ explosion: MissileExplosion) -> CGFloat {
        let progress = max(0, min(1, explosion.age / max(0.0001, explosion.maxAge)))
        if progress < 0.5 {
            return explosion.maxRadius * (progress / 0.5)
        }
        return explosion.maxRadius * ((1 - progress) / 0.5)
    }

    private func missileCityPosition(index: Int) -> CGPoint {
        let x = 0.12 + CGFloat(index) * 0.15
        return CGPoint(x: x, y: 0.9)
    }

    private func missileBasePosition(index: Int) -> CGPoint {
        let values: [CGFloat] = [0.16, 0.5, 0.84]
        let safe = min(max(index, 0), values.count - 1)
        return CGPoint(x: values[safe], y: 0.935)
    }

    private var snakeCols: Int32 {
        switch snakeBoardSizeLevel {
        case 1: return 12
        case 2: return 18
        case 3: return 28
        default: return 40
        }
    }

    private var snakeRows: Int32 {
        switch snakeBoardSizeLevel {
        case 1: return 8
        case 2: return 11
        case 3: return 16
        default: return 24
        }
    }

    private var snakeBoardWidthScale: CGFloat {
        switch snakeBoardSizeLevel {
        case 1: return 0.64
        case 2: return 0.76
        case 3: return 0.88
        default: return 0.98
        }
    }

    private var snakeBoardHeightScale: CGFloat {
        switch snakeBoardSizeLevel {
        case 1: return 0.52
        case 2: return 0.62
        case 3: return 0.74
        default: return 0.86
        }
    }

    private var snakeView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height
            let targetBoardWidth = width * snakeBoardWidthScale
            let targetBoardHeight = height * snakeBoardHeightScale
            let cellSize = min(targetBoardWidth / CGFloat(snakeCols), targetBoardHeight / CGFloat(snakeRows))
            let boardWidth = cellSize * CGFloat(snakeCols)
            let boardHeight = cellSize * CGFloat(snakeRows)
            let boardOriginX = (width - boardWidth) * 0.5
            let boardOriginY = height * 0.15
            let interpolationOffsetX = (snakeRunning && snakeGameOver == false)
                ? CGFloat(snakeDirection.dx) * (snakeRenderProgress - 1)
                : 0
            let interpolationOffsetY = (snakeRunning && snakeGameOver == false)
                ? CGFloat(snakeDirection.dy) * (snakeRenderProgress - 1)
                : 0

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: boardWidth, height: boardHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                    )
                    .position(x: boardOriginX + (boardWidth * 0.5), y: boardOriginY + (boardHeight * 0.5))

                ForEach(Array(snakeBody.enumerated()), id: \.offset) { idx, segment in
                    let isHead = idx == 0
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isHead ? phosphorColor : phosphorColor.opacity(0.8))
                        .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                        .position(
                            x: boardOriginX + (CGFloat(segment.x) + 0.5 + interpolationOffsetX) * cellSize,
                            y: boardOriginY + (CGFloat(segment.y) + 0.5 + interpolationOffsetY) * cellSize
                        )
                        .shadow(color: phosphorColor.opacity(isHead ? 0.6 : 0.3), radius: isHead ? 3 : 1)
                }

                Circle()
                    .fill(Color.red.opacity(0.95))
                    .frame(width: cellSize * 0.78, height: cellSize * 0.78)
                    .position(
                        x: boardOriginX + (CGFloat(snakeFood.x) + 0.5) * cellSize,
                        y: boardOriginY + (CGFloat(snakeFood.y) + 0.5) * cellSize
                    )
                    .shadow(color: Color.red.opacity(0.5), radius: 2)

                VStack(spacing: 4) {
                    Text("SNAKE  \(snakeScore)")
                        .font(displayFont(size: max(20, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(snakeGameOver ? "GAME OVER" : (snakeRunning ? "RUN" : "READY"))
                        .font(.system(size: max(12, height * 0.045), weight: .regular, design: .monospaced))
                        .foregroundStyle(snakeGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("← ↑ ↓ → direccion · click izq start/pausa · der reset")
                    .font(.system(size: max(11, height * 0.041), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { snakeRunning.toggle() },
                    onRightClick: { resetSnakeGame() }
                )
            )
            .frame(width: width, height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private func activateSnakeMode() {
        if snakeBody.isEmpty {
            resetSnakeGame()
        }
        installSnakeKeyboardMonitorIfNeeded()
        startSnakeLoopIfNeeded()
    }

    private func deactivateSnakeMode() {
        snakeTimer?.setEventHandler {}
        snakeTimer?.cancel()
        snakeTimer = nil
        if let monitor = snakeKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            snakeKeyboardMonitor = nil
        }
    }

    private func startSnakeLoopIfNeeded() {
        guard snakeTimer == nil else { return }
        snakeLastStepTime = CACurrentMediaTime()
        snakeStepAccumulator = 0
        snakeRenderProgress = 1
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            let now = CACurrentMediaTime()
            DispatchQueue.main.async {
                updateSnakeFrame(currentTime: now)
            }
        }
        timer.resume()
        snakeTimer = timer
    }

    private func installSnakeKeyboardMonitorIfNeeded() {
        guard snakeKeyboardMonitor == nil else { return }
        snakeKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard utilityMode == .snake else { return event }
            switch event.keyCode {
            case 123: // left
                queueSnakeDirection(CGVector(dx: -1, dy: 0))
                snakeRunning = true
                return nil
            case 124: // right
                queueSnakeDirection(CGVector(dx: 1, dy: 0))
                snakeRunning = true
                return nil
            case 125: // down
                queueSnakeDirection(CGVector(dx: 0, dy: 1))
                snakeRunning = true
                return nil
            case 126: // up
                queueSnakeDirection(CGVector(dx: 0, dy: -1))
                snakeRunning = true
                return nil
            case 49: // space
                snakeRunning.toggle()
                return nil
            case 53: // esc
                resetSnakeGame()
                return nil
            default:
                return event
            }
        }
    }

    private func queueSnakeDirection(_ direction: CGVector) {
        if snakeDirection.dx + direction.dx == 0, snakeDirection.dy + direction.dy == 0 {
            return
        }
        snakePendingDirection = direction
    }

    private func resetSnakeGame() {
        snakeRunning = false
        snakeGameOver = false
        snakeScore = 0
        snakeDirection = CGVector(dx: 1, dy: 0)
        snakePendingDirection = CGVector(dx: 1, dy: 0)
        snakeBody = [SIMD2<Int32>(8, 6), SIMD2<Int32>(7, 6), SIMD2<Int32>(6, 6)]
        snakeStepAccumulator = 0
        snakeRenderProgress = 1
        snakeLastStepTime = CACurrentMediaTime()
        placeSnakeFood()
    }

    private func placeSnakeFood() {
        let occupied = Set(snakeBody.map { "\($0.x),\($0.y)" })
        for _ in 0..<300 {
            let candidate = SIMD2<Int32>(Int32(Int.random(in: 0..<Int(snakeCols))), Int32(Int.random(in: 0..<Int(snakeRows))))
            if occupied.contains("\(candidate.x),\(candidate.y)") == false {
                snakeFood = candidate
                return
            }
        }
        snakeFood = SIMD2<Int32>(0, 0)
    }

    private func updateSnakeFrame(currentTime now: TimeInterval) {
        guard utilityMode == .snake else { return }
        let stepInterval: TimeInterval = 0.105
        if snakeLastStepTime == 0 {
            snakeLastStepTime = now
            snakeRenderProgress = 1
            return
        }

        let delta = max(0, min(0.05, now - snakeLastStepTime))
        snakeLastStepTime = now

        guard snakeRunning else {
            snakeStepAccumulator = 0
            snakeRenderProgress = 1
            return
        }

        snakeStepAccumulator += delta
        var safety = 0
        while snakeStepAccumulator >= stepInterval, snakeRunning, safety < 3 {
            snakeStepAccumulator -= stepInterval
            advanceSnakeOneStep()
            safety += 1
        }

        if snakeRunning {
            snakeRenderProgress = CGFloat(max(0, min(1, snakeStepAccumulator / stepInterval)))
        } else {
            snakeRenderProgress = 1
        }
    }

    private func advanceSnakeOneStep() {
        snakeDirection = snakePendingDirection
        guard var newHead = snakeBody.first else { return }
        newHead.x += Int32(snakeDirection.dx)
        newHead.y += Int32(snakeDirection.dy)

        if newHead.x < 0 || newHead.x >= snakeCols || newHead.y < 0 || newHead.y >= snakeRows {
            snakeRunning = false
            snakeGameOver = true
            triggerFlash()
            return
        }
        if snakeBody.contains(where: { $0 == newHead }) {
            snakeRunning = false
            snakeGameOver = true
            triggerFlash()
            return
        }

        snakeBody.insert(newHead, at: 0)
        if newHead == snakeFood {
            snakeScore += 10
            placeSnakeFood()
        } else {
            snakeBody.removeLast()
        }
    }

    private var isSpanishLanguage: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
    }

    private func localizedThisDayText(_ event: ThisDayEvent) -> String {
        isSpanishLanguage ? event.es : event.en
    }

    private var todayMonthDay: (month: Int, day: Int) {
        let components = Calendar.current.dateComponents([.month, .day], from: viewModel.now)
        return (components.month ?? 1, components.day ?? 1)
    }

    private var todayInHistoryLocalEvents: [ThisDayEvent] {
        let md = todayMonthDay
        let all: [ThisDayEvent] = [
            ThisDayEvent(id: "0219-1473", month: 2, day: 19, year: 1473, es: "Nace Nicolas Copernico, astronomo.", en: "Nicolaus Copernicus is born."),
            ThisDayEvent(id: "0219-1878", month: 2, day: 19, year: 1878, es: "Thomas Edison patenta el fonografo.", en: "Thomas Edison patents the phonograph."),
            ThisDayEvent(id: "0219-1945", month: 2, day: 19, year: 1945, es: "Comienza la batalla de Iwo Jima.", en: "The Battle of Iwo Jima begins."),
            ThisDayEvent(id: "0220-1962", month: 2, day: 20, year: 1962, es: "John Glenn orbita la Tierra.", en: "John Glenn orbits Earth."),
            ThisDayEvent(id: "0221-1848", month: 2, day: 21, year: 1848, es: "Se publica el Manifiesto Comunista.", en: "The Communist Manifesto is published."),
            ThisDayEvent(id: "0301-1872", month: 3, day: 1, year: 1872, es: "Yellowstone se convierte en el primer parque nacional.", en: "Yellowstone becomes the first national park."),
            ThisDayEvent(id: "0310-1876", month: 3, day: 10, year: 1876, es: "Primera llamada telefonica de Alexander Graham Bell.", en: "Alexander Graham Bell makes the first telephone call."),
            ThisDayEvent(id: "0321-1960", month: 3, day: 21, year: 1960, es: "Masacre de Sharpeville en Sudafrica.", en: "Sharpeville massacre in South Africa."),
            ThisDayEvent(id: "0404-1968", month: 4, day: 4, year: 1968, es: "Asesinan a Martin Luther King Jr.", en: "Martin Luther King Jr. is assassinated."),
            ThisDayEvent(id: "0412-1961", month: 4, day: 12, year: 1961, es: "Yuri Gagarin viaja al espacio.", en: "Yuri Gagarin travels to space."),
            ThisDayEvent(id: "0509-1950", month: 5, day: 9, year: 1950, es: "Declaracion Schuman, origen de la UE.", en: "Schuman Declaration, origin of the EU."),
            ThisDayEvent(id: "0525-1961", month: 5, day: 25, year: 1961, es: "Kennedy anuncia la meta de llegar a la Luna.", en: "Kennedy announces the goal to reach the Moon."),
            ThisDayEvent(id: "0606-1944", month: 6, day: 6, year: 1944, es: "Desembarco de Normandia (Dia D).", en: "D-Day Normandy landings."),
            ThisDayEvent(id: "0623-1912", month: 6, day: 23, year: 1912, es: "Nace Alan Turing.", en: "Alan Turing is born."),
            ThisDayEvent(id: "0704-1776", month: 7, day: 4, year: 1776, es: "Declaracion de Independencia de EE. UU.", en: "U.S. Declaration of Independence."),
            ThisDayEvent(id: "0711-1893", month: 7, day: 11, year: 1893, es: "Nace Walter B. Pitkin (dato historico de referencia).", en: "Walter B. Pitkin is born."),
            ThisDayEvent(id: "0720-1969", month: 7, day: 20, year: 1969, es: "Llegada del Apolo 11 a la Luna.", en: "Apollo 11 Moon landing."),
            ThisDayEvent(id: "0806-1945", month: 8, day: 6, year: 1945, es: "Bomba atomica sobre Hiroshima.", en: "Atomic bomb dropped on Hiroshima."),
            ThisDayEvent(id: "0815-1947", month: 8, day: 15, year: 1947, es: "Independencia de la India.", en: "India gains independence."),
            ThisDayEvent(id: "0828-1963", month: 8, day: 28, year: 1963, es: "Discurso 'I Have a Dream'.", en: "The 'I Have a Dream' speech."),
            ThisDayEvent(id: "0908-1504", month: 9, day: 8, year: 1504, es: "Miguel Angel finaliza el David (fecha de referencia habitual).", en: "Michelangelo completes David (commonly cited date)."),
            ThisDayEvent(id: "0911-2001", month: 9, day: 11, year: 2001, es: "Atentados del 11-S en EE. UU.", en: "9/11 attacks in the United States."),
            ThisDayEvent(id: "1004-1957", month: 10, day: 4, year: 1957, es: "Lanzamiento del Sputnik 1.", en: "Sputnik 1 is launched."),
            ThisDayEvent(id: "1012-1492", month: 10, day: 12, year: 1492, es: "Llegada de Colon a America.", en: "Columbus reaches the Americas."),
            ThisDayEvent(id: "1109-1989", month: 11, day: 9, year: 1989, es: "Caida del Muro de Berlin.", en: "Fall of the Berlin Wall."),
            ThisDayEvent(id: "1122-1963", month: 11, day: 22, year: 1963, es: "Asesinato de John F. Kennedy.", en: "John F. Kennedy is assassinated."),
            ThisDayEvent(id: "1201-1913", month: 12, day: 1, year: 1913, es: "Ford introduce la cadena de montaje moderna.", en: "Ford introduces modern assembly line production."),
            ThisDayEvent(id: "1210-1901", month: 12, day: 10, year: 1901, es: "Primera entrega de los premios Nobel.", en: "First Nobel Prize ceremony."),
            ThisDayEvent(id: "1225-1991", month: 12, day: 25, year: 1991, es: "Disolucion oficial de la URSS.", en: "Official dissolution of the USSR.")
        ]

        let matches = all.filter { $0.month == md.month && $0.day == md.day }
        if matches.isEmpty == false {
            return matches.sorted { $0.year < $1.year }
        }

        return [
            ThisDayEvent(
                id: "fallback-\(md.month)-\(md.day)",
                month: md.month,
                day: md.day,
                year: Calendar.current.component(.year, from: viewModel.now),
                es: "Sin eventos cargados para hoy en la base local.",
                en: "No events loaded for today in the local database."
            )
        ]
    }

    private var activeTodayInHistoryEvents: [ThisDayEvent] {
        guard todayEventsInitialLoadCompleted else { return [] }
        return todayInternetEvents.isEmpty ? todayInHistoryLocalEvents : todayInternetEvents
    }

    private var rotatingTodayInHistoryEvents: [ThisDayEvent] {
        let source = activeTodayInHistoryEvents
        guard source.isEmpty == false else { return [] }
        let count = 5
        let offset = source.isEmpty ? 0 : (todayEventsRotationOffset % source.count)
        return (0..<count).map { source[($0 + offset) % source.count] }
    }

    private var todayInHistoryView: some View {
        return VStack(alignment: .leading, spacing: 10) {
            if todayEventsLoading {
                Text(isSpanishLanguage ? "actualizando desde internet..." : "updating from internet...")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .padding(.horizontal, 18)
                    .padding(.top, 56)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rotatingTodayInHistoryEvents) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(event.year)")
                                .font(displayFont(size: 18, weight: .bold))
                                .foregroundStyle(phosphorColor)
                                .frame(width: 84, alignment: .leading)

                            Text(localizedThisDayText(event))
                                .font(.system(size: 17, weight: .regular, design: .monospaced))
                                .foregroundStyle(phosphorDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 3)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 10)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                advanceTodayInHistoryEventsBlock()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var activeMusicThoughtQuote: MusicThoughtQuote? {
        guard musicThoughtQuotes.isEmpty == false else { return nil }
        let index = max(0, musicThoughtIndex % musicThoughtQuotes.count)
        return musicThoughtQuotes[index]
    }

    private var musicThoughtView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if musicThoughtLoading && musicThoughtQuotes.isEmpty {
                Text(isSpanishLanguage ? "cargando frases..." : "loading thoughts...")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .padding(.horizontal, 18)
                    .padding(.top, 56)
            }

            if let quote = activeMusicThoughtQuote {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\"\(quote.quote)\"")
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(quote.author)
                            .font(displayFont(size: 20, weight: .bold))
                            .foregroundStyle(phosphorDim)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 56)
                    .padding(.bottom, 12)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    advanceMusicThoughtQuote()
                }
            } else if musicThoughtLoading == false {
                Text(isSpanishLanguage ? "sin frases disponibles" : "no thoughts available")
                    .font(displayFont(size: 20, weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .padding(.horizontal, 18)
                    .padding(.top, 64)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var raeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            TextField(L10n.raePlaceholder, text: $raeSearchText)
                .font(.system(size: 31, weight: .medium, design: .monospaced))
                .foregroundStyle(phosphorColor)
                .textFieldStyle(.plain)
                .padding(.horizontal, 18)
                .frame(height: 62)
                .background(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(phosphorColor.opacity(0.55), lineWidth: 1.3)
                )
                .onSubmit {
                    searchInRAE()
                }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(raeResultLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 25, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 18)
        .padding(.top, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func activateTodayInHistoryMode() {
        startTodayInHistoryTimerIfNeeded()
        updateTodayInHistoryRotationForCurrentHour()
        fetchTodayInHistoryFromInternet(force: true)
    }

    private func deactivateTodayInHistoryMode() {
        todayEventsTimer?.invalidate()
        todayEventsTimer = nil
    }

    private func startTodayInHistoryTimerIfNeeded() {
        guard todayEventsTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { _ in
            updateTodayInHistoryRotationForCurrentHour()
            fetchTodayInHistoryFromInternet(force: false)
        }
        timer.tolerance = 30.0
        RunLoop.main.add(timer, forMode: .common)
        todayEventsTimer = timer
    }

    private func updateTodayInHistoryRotationForCurrentHour() {
        let events = activeTodayInHistoryEvents
        guard events.isEmpty == false else {
            todayEventsRotationOffset = 0
            return
        }

        let blockSize = 5
        let hour = Calendar.current.component(.hour, from: Date())
        todayEventsRotationOffset = (hour * blockSize) % events.count
    }

    private func advanceTodayInHistoryEventsBlock() {
        let events = activeTodayInHistoryEvents
        guard events.isEmpty == false else { return }
        let blockSize = 5
        todayEventsRotationOffset = (todayEventsRotationOffset + blockSize) % events.count
    }

    private func fetchTodayInHistoryFromInternet(force: Bool) {
        if todayEventsLoading { return }
        if force == false, let last = todayEventsLastRefresh, Date().timeIntervalSince(last) < 3600 {
            return
        }
        todayEventsLoading = true
        let md = todayMonthDay
        let lang = isSpanishLanguage ? "es" : "en"
        let urlString = "https://api.wikimedia.org/feed/v1/wikipedia/\(lang)/onthisday/all/\(String(format: "%02d", md.month))/\(String(format: "%02d", md.day))"
        guard let url = URL(string: urlString) else {
            todayEventsLoading = false
            return
        }

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await MainActor.run {
                        todayEventsLoading = false
                    }
                    return
                }

                let decoded = try JSONDecoder().decode(OnThisDayResponse.self, from: data)
                let selected = (decoded.selected ?? []).prefix(18).map { entry in
                    let year = entry.year ?? 0
                    let text = (entry.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return ThisDayEvent(
                        id: "net-s-\(year)-\(text.hashValue)",
                        month: md.month,
                        day: md.day,
                        year: year,
                        es: text,
                        en: text
                    )
                }
                let events = (decoded.events ?? []).prefix(14).map { entry in
                    let year = entry.year ?? 0
                    let text = (entry.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return ThisDayEvent(
                        id: "net-e-\(year)-\(text.hashValue)",
                        month: md.month,
                        day: md.day,
                        year: year,
                        es: text,
                        en: text
                    )
                }
                let births = (decoded.births ?? []).prefix(8).map { entry in
                    let year = entry.year ?? 0
                    let text = (entry.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return ThisDayEvent(
                        id: "net-b-\(year)-\(text.hashValue)",
                        month: md.month,
                        day: md.day,
                        year: year,
                        es: "Nacimiento: \(text)",
                        en: "Birth: \(text)"
                    )
                }
                let deaths = (decoded.deaths ?? []).prefix(8).map { entry in
                    let year = entry.year ?? 0
                    let text = (entry.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return ThisDayEvent(
                        id: "net-d-\(year)-\(text.hashValue)",
                        month: md.month,
                        day: md.day,
                        year: year,
                        es: "Fallecimiento: \(text)",
                        en: "Death: \(text)"
                    )
                }

                var seen = Set<String>()
                let merged = (selected + events + births + deaths).filter { item in
                    let normalized = "\(item.es)|\(item.en)".lowercased()
                    if normalized.isEmpty { return false }
                    if seen.contains(normalized) { return false }
                    seen.insert(normalized)
                    return true
                }
                let finalEvents = Array(merged.prefix(30))

                await MainActor.run {
                    let hasChanges = finalEvents.map(\.id) != todayInternetEvents.map(\.id)
                    if hasChanges {
                        todayInternetEvents = finalEvents
                    }
                    todayEventsInitialLoadCompleted = true
                    updateTodayInHistoryRotationForCurrentHour()
                    todayEventsLastRefresh = Date()
                    todayEventsLoading = false
                }
            } catch {
                await MainActor.run {
                    todayEventsInitialLoadCompleted = true
                    todayEventsLoading = false
                }
            }
        }
    }

    private func activateMusicThoughtMode() {
        startMusicThoughtTimerIfNeeded()
        fetchMusicThoughtQuotes(force: true)
    }

    private func deactivateMusicThoughtMode() {
        musicThoughtTimer?.invalidate()
        musicThoughtTimer = nil
    }

    private func searchInRAE() {
        let cleaned = raeSearchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard cleaned.isEmpty == false else {
            raeResultLines = [L10n.raeInvalidWord]
            return
        }
        raeResultLines = [isSpanishLanguage ? "buscando..." : "searching..."]
        raeSearchRequestID += 1
        let requestID = raeSearchRequestID
        let isSpanish = isSpanishLanguage

        Task.detached(priority: .userInitiated) {
            let rawOutput = Self.runRAECurlSearch(term: cleaned)
            let lines = Self.parseRAEScrapedLines(from: rawOutput, term: cleaned, isSpanishLanguage: isSpanish)
            await MainActor.run {
                guard requestID == raeSearchRequestID else { return }
                raeResultLines = lines
            }
        }
    }

    private nonisolated static func runRAECurlSearch(term: String) -> String {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let directURL = "https://r.jina.ai/http://dle.rae.es/?w=\(encoded)"
        let directOutput = runCurl(url: directURL)
        if directOutput.contains("Definición") || directOutput.contains("Definicion") {
            return directOutput
        }

        if let suggestedURL = extractSuggestedRAEEntryURL(from: directOutput) {
            let suggestedOutput = runCurl(url: suggestedURL)
            if suggestedOutput.isEmpty == false {
                return suggestedOutput
            }
        }

        let fallbackURL = "https://r.jina.ai/http://dle.rae.es/srv/search?m=30&w=\(encoded)"
        let fallbackOutput = runCurl(url: fallbackURL)
        if let suggestedURL = extractSuggestedRAEEntryURL(from: fallbackOutput) {
            let suggestedOutput = runCurl(url: suggestedURL)
            if suggestedOutput.isEmpty == false {
                return suggestedOutput
            }
        }

        return fallbackOutput.isEmpty ? directOutput : fallbackOutput
    }

    private nonisolated static func runCurl(url: String) -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = ["-sS", "-L", "--max-time", "15", url]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus == 0, let output = String(data: outputData, encoding: .utf8) {
            return output
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if let errorText = String(data: errorData, encoding: .utf8), errorText.isEmpty == false {
            return errorText
        }
        return ""
    }

    private nonisolated static func extractSuggestedRAEEntryURL(from raw: String) -> String? {
        guard raw.isEmpty == false else { return nil }
        let pattern = #"https?://dle\.rae\.es/[^\s\)"]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        let matches = regex.matches(in: raw, options: [], range: range)
        for match in matches {
            guard let valueRange = Range(match.range, in: raw) else { continue }
            let found = String(raw[valueRange])
            if found.contains("?w=") || found.contains("/srv/search") || found.contains("/m=wotd") {
                continue
            }
            return "https://r.jina.ai/\(found)"
        }
        return nil
    }

    private nonisolated static func parseRAEScrapedLines(from raw: String, term: String, isSpanishLanguage: Bool) -> [String] {
        guard raw.isEmpty == false else {
            return [isSpanishLanguage ? "error consultando RAE" : "error fetching RAE"]
        }

        var body = raw.replacingOccurrences(of: "\r\n", with: "\n")
        if let markerRange = body.range(of: "Markdown Content:") {
            body = String(body[markerRange.upperBound...])
        }

        let lowered = body.lowercased()
        let hasNoLemmaMatch =
            lowered.contains("no se ha encontrado ningún lema coincidente") ||
            lowered.contains("no se ha encontrado ningun lema coincidente") ||
            lowered.contains("no matching lemma")
        let hasNotInDictionary =
            lowered.contains("no está en el diccionario") ||
            lowered.contains("no esta en el diccionario")
        if hasNoLemmaMatch {
            return [
                isSpanishLanguage
                    ? "La palabra \"\(term)\" no está en el diccionario."
                    : "The word \"\(term)\" is not in the dictionary."
            ]
        }
        if hasNotInDictionary,
           lowered.contains("definición") == false,
           lowered.contains("definicion") == false {
            return [
                isSpanishLanguage
                    ? "La palabra \"\(term)\" no está en el diccionario."
                    : "The word \"\(term)\" is not in the dictionary."
            ]
        }

        if let definitionRange = body.range(of: "\nDefinición\n", options: [.caseInsensitive]) {
            body = String(body[definitionRange.lowerBound...])
        }
        if let dayRange = body.range(of: "\nPalabra del día", options: [.caseInsensitive]) {
            body = String(body[..<dayRange.lowerBound])
        }
        if let resourcesRange = body.range(of: "\nOtros diccionarios y recursos", options: [.caseInsensitive]) {
            body = String(body[..<resourcesRange.lowerBound])
        }

        let lines = body
            .components(separatedBy: .newlines)
            .map { line in
                var value = line.trimmingCharacters(in: .whitespacesAndNewlines)
                value = value.replacingOccurrences(of: #"\[(.*?)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
                value = value.replacingOccurrences(of: #"_([^_]+)_"#, with: "$1", options: .regularExpression)
                value = value.replacingOccurrences(of: #"^###\s+"#, with: "", options: .regularExpression)
                value = value.replacingOccurrences(of: #"^\d+\.\s+\d+\.\s*"#, with: "", options: .regularExpression)
                value = value.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                value = value.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { line in
                line.isEmpty == false &&
                line != "----------" &&
                line != "Definición" &&
                line.hasPrefix("Title:") == false &&
                line.hasPrefix("URL Source:") == false &&
                line.hasPrefix("Markdown Content:") == false
            }

        let result = Array(lines.prefix(24))
        if result.isEmpty {
            return [
                isSpanishLanguage
                    ? "sin resultados para \"\(term)\""
                    : "no results for \"\(term)\""
            ]
        }
        return result
    }

    private func startMusicThoughtTimerIfNeeded() {
        guard musicThoughtTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { _ in
            advanceMusicThoughtQuote()
            fetchMusicThoughtQuotes(force: false)
        }
        timer.tolerance = 30.0
        RunLoop.main.add(timer, forMode: .common)
        musicThoughtTimer = timer
    }

    private func advanceMusicThoughtQuote() {
        guard musicThoughtQuotes.isEmpty == false else {
            fetchMusicThoughtQuotes(force: true)
            return
        }
        musicThoughtIndex = (musicThoughtIndex + 1) % max(1, musicThoughtQuotes.count)
    }

    private func fetchMusicThoughtQuotes(force: Bool) {
        if musicThoughtLoading { return }
        if force == false, let last = musicThoughtLastRefresh, Date().timeIntervalSince(last) < 300 {
            return
        }
        musicThoughtLoading = true

        let host = isSpanishLanguage ? "https://es.musicthoughts.com/new" : "https://musicthoughts.com/new"
        guard let url = URL(string: host) else {
            musicThoughtLoading = false
            return
        }

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await MainActor.run {
                        musicThoughtLoading = false
                    }
                    return
                }

                let parsed = parseMusicThoughtQuotes(from: data)
                await MainActor.run {
                    if parsed.isEmpty == false {
                        let oldIDs = musicThoughtQuotes.map(\.id)
                        let newIDs = parsed.map(\.id)
                        if oldIDs != newIDs {
                            let previousID = activeMusicThoughtQuote?.id
                            musicThoughtQuotes = parsed
                            if let previousID, let found = parsed.firstIndex(where: { $0.id == previousID }) {
                                musicThoughtIndex = found
                            } else {
                                musicThoughtIndex = 0
                            }
                        }
                    }
                    musicThoughtLastRefresh = Date()
                    musicThoughtLoading = false
                }
            } catch {
                await MainActor.run {
                    musicThoughtLoading = false
                }
            }
        }
    }

    private func parseMusicThoughtQuotes(from data: Data) -> [MusicThoughtQuote] {
        guard let html = String(data: data, encoding: .utf8), html.isEmpty == false else {
            return []
        }

        let pattern = #"<blockquote[^>]*>[\s\S]*?<q[^>]*>(.*?)</q>[\s\S]*?<cite[^>]*>\s*<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>\s*</cite>[\s\S]*?</blockquote>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let fullRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: fullRange)
        if matches.isEmpty {
            return []
        }

        var seen = Set<String>()
        var quotes: [MusicThoughtQuote] = []
        quotes.reserveCapacity(min(120, matches.count))

        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            guard
                let quoteRange = Range(match.range(at: 1), in: html),
                let linkRange = Range(match.range(at: 2), in: html),
                let authorRange = Range(match.range(at: 3), in: html)
            else { continue }

            let quoteRaw = String(html[quoteRange])
            let linkPath = String(html[linkRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let authorRaw = String(html[authorRange])

            let quoteText = cleanMusicThoughtHTMLFragment(quoteRaw)
            var authorText = cleanMusicThoughtHTMLFragment(authorRaw)
            if authorText.isEmpty {
                authorText = isSpanishLanguage ? "autor desconocido" : "unknown author"
            }

            if quoteText.isEmpty { continue }

            let dedupeKey = (quoteText + "|" + authorText).lowercased()
            if seen.contains(dedupeKey) { continue }
            seen.insert(dedupeKey)

            let id = dedupeKey + "|" + linkPath
            quotes.append(MusicThoughtQuote(id: id, quote: quoteText, author: authorText, linkPath: linkPath))
            if quotes.count >= 120 { break }
        }

        return quotes
    }

    private func cleanMusicThoughtHTMLFragment(_ fragment: String) -> String {
        var html = fragment
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<br\\s+[^>]*>", with: "\n", options: .regularExpression)

        if let data = html.data(using: .utf8),
           let attributed = try? NSAttributedString(
               data: data,
               options: [
                   .documentType: NSAttributedString.DocumentType.html,
                   .characterEncoding: String.Encoding.utf8.rawValue
               ],
               documentAttributes: nil
           ) {
            html = attributed.string
        } else {
            html = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }

        return html
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    #endif

    private var displayedSecondsText: String {
        switch topMode {
        case .clock:
            return viewModel.secondsText
        case .worldClock:
            return worldClockSecondsText
        case .uptime:
            return uptimeText.seconds
        case .stopwatch:
            return stopwatchText.seconds
        case .countdown:
            return countdownText.seconds
        case .alarm:
            return "00"
        }
    }

    private struct WorldCity {
        let code: String
        let timeZoneID: String
    }

    private var worldCities: [WorldCity] {
        [
            WorldCity(code: "MAD", timeZoneID: "Europe/Madrid"),
            WorldCity(code: "NYC", timeZoneID: "America/New_York"),
            WorldCity(code: "TKY", timeZoneID: "Asia/Tokyo"),
            WorldCity(code: "LON", timeZoneID: "Europe/London"),
            WorldCity(code: "LAX", timeZoneID: "America/Los_Angeles"),
            WorldCity(code: "MEX", timeZoneID: "America/Mexico_City"),
            WorldCity(code: "SYD", timeZoneID: "Australia/Sydney")
        ]
    }

    private var selectedWorldCity: WorldCity {
        guard worldCities.isEmpty == false else {
            return WorldCity(code: "UTC", timeZoneID: "UTC")
        }
        let safeIndex = min(max(selectedWorldCityIndex, 0), worldCities.count - 1)
        return worldCities[safeIndex]
    }

    private var worldClockCityCode: String {
        selectedWorldCity.code
    }

    private var worldClockHourMinuteText: String {
        guard let timeZone = TimeZone(identifier: selectedWorldCity.timeZoneID) else {
            return "--:--"
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: viewModel.now)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        return String(format: "%02d:%02d", hours, minutes)
    }

    private var worldClockSecondsText: String {
        guard let timeZone = TimeZone(identifier: selectedWorldCity.timeZoneID) else {
            return "--"
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.second], from: viewModel.now)
        let seconds = components.second ?? 0
        return String(format: "%02d", seconds)
    }

    private func rotateWorldCityForward() {
        guard worldCities.isEmpty == false else { return }
        selectedWorldCityIndex = (selectedWorldCityIndex + 1) % worldCities.count
    }

    private func rotateWorldCityBackward() {
        guard worldCities.isEmpty == false else { return }
        selectedWorldCityIndex = (selectedWorldCityIndex - 1 + worldCities.count) % worldCities.count
    }

    private var uptimeText: (hourMinute: String, seconds: String) {
        let totalSeconds = max(0, Int(ProcessInfo.processInfo.systemUptime))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (
            hourMinute: "\(hours):" + String(format: "%02d", minutes),
            seconds: String(format: "%02d", seconds)
        )
    }

    private var stopwatchText: (hourMinute: String, seconds: String) {
        let display = stopwatchDisplayValues(at: Date())
        return (
            hourMinute: "\(display.minutes):" + String(format: "%02d", display.seconds),
            seconds: String(format: "%02d", display.centiseconds)
        )
    }

    private var stopwatchPrimaryButtonTitle: String {
        (stopwatchRunning || stopwatchPrestartInProgress) ? L10n.stop : L10n.start
    }

    private var stopwatchPreButtonTitle: String {
        "\(L10n.stopwatchPrecountdownShort) \(stopwatchPrestartCountdownEnabled ? "on" : "off")"
    }

    private var countdownPrimaryButtonTitle: String {
        countdownRunning ? "pausa" : L10n.start
    }

    private var countdownText: (hourMinute: String, seconds: String) {
        let totalSeconds = max(0, countdownDisplayTotalSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (
            hourMinute: "\(hours):" + String(format: "%02d", minutes),
            seconds: String(format: "%02d", seconds)
        )
    }

    private func countdownButton(title: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(displayFont(size: size, weight: .regular))
                .foregroundStyle(phosphorColor)
                .frame(width: 148)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(phosphorColor.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(PressableCountdownButtonStyle(phosphorColor: phosphorColor))
    }

    private func startStopwatch() {
        guard stopwatchRunning == false else { return }
        guard stopwatchPrestartInProgress == false else { return }

        if stopwatchPrestartCountdownEnabled {
            startStopwatchPrestartCountdown()
            return
        }
        beginStopwatchRun()
    }

    private func toggleStopwatchRunState() {
        if stopwatchRunning || stopwatchPrestartInProgress {
            stopStopwatch()
        } else {
            startStopwatch()
        }
    }

    private func stopStopwatch() {
        if stopwatchPrestartInProgress {
            cancelStopwatchPrestartCountdown()
            return
        }
        guard stopwatchRunning else { return }
        if let startDate = stopwatchStartDate {
            let elapsedCentiseconds = max(0, Int((Date().timeIntervalSince(startDate) * 100).rounded(.down)))
            stopwatchAccumulatedCentiseconds += elapsedCentiseconds
        }
        stopwatchStartDate = nil
        stopwatchRunning = false
    }

    private func resetStopwatch() {
        cancelStopwatchPrestartCountdown()
        stopwatchRunning = false
        stopwatchAccumulatedCentiseconds = 0
        stopwatchStartDate = nil
    }

    private func stopwatchDisplayValues(at referenceDate: Date) -> (minutes: Int, seconds: Int, centiseconds: Int) {
        let totalCentiseconds = stopwatchDisplayTotalCentiseconds(at: referenceDate)
        let minutes = totalCentiseconds / 6000
        let seconds = (totalCentiseconds / 100) % 60
        let centiseconds = totalCentiseconds % 100
        return (minutes, seconds, centiseconds)
    }

    private func stopwatchDisplayTotalCentiseconds(at referenceDate: Date) -> Int {
        var totalCentiseconds = stopwatchAccumulatedCentiseconds
        if stopwatchRunning, let startDate = stopwatchStartDate {
            totalCentiseconds += max(0, Int((referenceDate.timeIntervalSince(startDate) * 100).rounded(.down)))
        }
        return max(0, totalCentiseconds)
    }

    private func beginStopwatchRun() {
        stopwatchStartDate = Date()
        stopwatchRunning = true
    }

    private func startStopwatchPrestartCountdown() {
        cancelStopwatchPrestartCountdown()
        stopwatchPrestartInProgress = true

        stopwatchPrestartTask = Task { @MainActor in
            for value in stride(from: 3, through: 1, by: -1) {
                stopwatchPrestartDisplayValue = value
                #if os(macOS)
                triggerFlash()
                #endif
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
            }

            stopwatchPrestartDisplayValue = nil
            stopwatchPrestartTask = nil
            stopwatchPrestartInProgress = false
            beginStopwatchRun()
        }
    }

    private func cancelStopwatchPrestartCountdown() {
        stopwatchPrestartTask?.cancel()
        stopwatchPrestartTask = nil
        stopwatchPrestartInProgress = false
        stopwatchPrestartDisplayValue = nil
    }

    private func startCountdown() {
        let configured = countdownConfiguredTotalSeconds
        if configured > 0 && (countdownInitialSeconds == 0 || countdownRemainingSeconds == 0 || configured != countdownInitialSeconds) {
            countdownInitialSeconds = configured
            countdownRemainingSeconds = configured
        }

        if countdownRemainingSeconds > 0 {
            countdownRunning = true
        }
    }

    private func toggleCountdownRunState() {
        if countdownRunning {
            countdownRunning = false
        } else {
            startCountdown()
        }
    }

    private func stopCountdown() {
        countdownRunning = false
        if countdownInitialSeconds == 0 {
            countdownInitialSeconds = countdownConfiguredTotalSeconds
        }
        countdownRemainingSeconds = countdownInitialSeconds
    }

    private func resetCountdown() {
        countdownRunning = false
        countdownSetHours = 0
        countdownSetMinutes = 0
        countdownSetSeconds = 0
        countdownInitialSeconds = 0
        countdownRemainingSeconds = 0
    }

    private func tickCountdown() {
        guard topMode == .countdown, countdownRunning else { return }
        if countdownRemainingSeconds > 0 {
            countdownRemainingSeconds -= 1
        }
        #if os(macOS)
        if countdownRemainingSeconds > 0, countdownRemainingSeconds <= 3 {
            playCountdownFinalSecondsBeep()
        }
        #endif
        if countdownRemainingSeconds <= 0 {
            countdownRemainingSeconds = 0
            countdownRunning = false
            #if os(macOS)
            triggerFlash()
            startCountdownAlarm()
            #endif
        }
    }

    #if os(macOS)
    private func playCountdownFinalSecondsBeep() {
        if countdownBeepPlayer == nil {
            prepareCountdownBeepPlayerIfNeeded()
        }

        if let player = countdownBeepPlayer {
            player.currentTime = 0
            player.play()
        } else {
            NSSound.beep()
        }
    }

    private func prepareCountdownBeepPlayerIfNeeded() {
        let bundle = Bundle.main
        let beepURL = bundle.url(forResource: "tic", withExtension: "mp3", subdirectory: "Assets")
            ?? bundle.url(forResource: "tic", withExtension: "mp3")

        guard let beepURL else {
            countdownBeepPlayer = nil
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: beepURL)
            player.numberOfLoops = 0
            player.prepareToPlay()
            countdownBeepPlayer = player
        } catch {
            countdownBeepPlayer = nil
        }
    }
    #endif

    private func incrementCountdownHour() {
        guard countdownRunning == false else { return }
        countdownSetHours = (countdownSetHours + 1) % 24
        syncCountdownFromSetValues()
    }

    private func decrementCountdownHour() {
        guard countdownRunning == false else { return }
        countdownSetHours = (countdownSetHours + 23) % 24
        syncCountdownFromSetValues()
    }

    private func incrementCountdownMinute() {
        guard countdownRunning == false else { return }
        countdownSetMinutes = (countdownSetMinutes + 1) % 60
        syncCountdownFromSetValues()
    }

    private func decrementCountdownMinute() {
        guard countdownRunning == false else { return }
        countdownSetMinutes = (countdownSetMinutes + 59) % 60
        syncCountdownFromSetValues()
    }

    private func incrementCountdownSecond() {
        guard countdownRunning == false else { return }
        countdownSetSeconds = (countdownSetSeconds + 1) % 60
        syncCountdownFromSetValues()
    }

    private func decrementCountdownSecond() {
        guard countdownRunning == false else { return }
        countdownSetSeconds = (countdownSetSeconds + 59) % 60
        syncCountdownFromSetValues()
    }

    private func incrementAlarmHour() {
        alarmSetHours = (alarmSetHours + 1) % 24
    }

    private func decrementAlarmHour() {
        alarmSetHours = (alarmSetHours + 23) % 24
    }

    private func incrementAlarmMinute() {
        alarmSetMinutes = (alarmSetMinutes + 1) % 60
    }

    private func decrementAlarmMinute() {
        alarmSetMinutes = (alarmSetMinutes + 59) % 60
    }

    private func syncCountdownFromSetValues() {
        countdownInitialSeconds = countdownConfiguredTotalSeconds
        countdownRemainingSeconds = countdownInitialSeconds
    }

    private var countdownConfiguredTotalSeconds: Int {
        (countdownSetHours * 3600) + (countdownSetMinutes * 60) + countdownSetSeconds
    }

    private var countdownDisplayTotalSeconds: Int {
        if countdownRunning {
            return countdownRemainingSeconds
        }
        if countdownRemainingSeconds > 0 {
            return countdownRemainingSeconds
        }
        return countdownConfiguredTotalSeconds
    }

    private var countdownDisplayHours: Int {
        countdownDisplayTotalSeconds / 3600
    }

    private var countdownDisplayMinutes: Int {
        (countdownDisplayTotalSeconds % 3600) / 60
    }

    private var countdownDisplaySeconds: Int {
        countdownDisplayTotalSeconds % 60
    }

    private func syncAlarmToCurrentTimeIfUnset() {
        guard alarmSetHours == 0, alarmSetMinutes == 0 else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: viewModel.now)
        alarmSetHours = components.hour ?? 0
        alarmSetMinutes = components.minute ?? 0
    }

    private func tickScheduledAlarm(now: Date) {
        guard alarmEnabled else { return }
        guard countdownAlarmActive == false else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return
        }

        let secondKey = "\(year)-\(month)-\(day)-\(hour)-\(minute)-\(second)"
        if secondKey == lastTriggeredAlarmSecondKey {
            return
        }

        guard hour == alarmSetHours, minute == alarmSetMinutes, second == 0 else { return }

        lastTriggeredAlarmSecondKey = secondKey
        triggerFlash()
        startGlobalAlarm(duration: 60)
    }

    private func incrementMetronomeBPM() {
        metronomeBPM = min(300, metronomeBPM + 1)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    private func decrementMetronomeBPM() {
        metronomeBPM = max(20, metronomeBPM - 1)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    private var allowedMetronomeNumerators: [Int] { [2, 3, 4, 5, 6, 7, 8] }

    private var allowedMetronomeDenominators: [Int] { [2, 4, 8, 16] }

    private func rotateMetronomeNumeratorForward() {
        rotateMetronomeValueForward(current: metronomeNumerator, values: allowedMetronomeNumerators) { next in
            metronomeNumerator = next
        }
    }

    private func rotateMetronomeNumeratorBackward() {
        rotateMetronomeValueBackward(current: metronomeNumerator, values: allowedMetronomeNumerators) { next in
            metronomeNumerator = next
        }
    }

    private func rotateMetronomeDenominatorForward() {
        rotateMetronomeValueForward(current: metronomeDenominator, values: allowedMetronomeDenominators) { next in
            metronomeDenominator = next
        }
    }

    private func rotateMetronomeDenominatorBackward() {
        rotateMetronomeValueBackward(current: metronomeDenominator, values: allowedMetronomeDenominators) { next in
            metronomeDenominator = next
        }
    }

    private func rotateMetronomeValueForward(current: Int, values: [Int], apply: (Int) -> Void) {
        guard let index = values.firstIndex(of: current) else {
            apply(values.first ?? current)
            return
        }
        let next = values[(index + 1) % values.count]
        apply(next)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    private func rotateMetronomeValueBackward(current: Int, values: [Int], apply: (Int) -> Void) {
        guard let index = values.firstIndex(of: current) else {
            apply(values.first ?? current)
            return
        }
        let prev = values[(index + values.count - 1) % values.count]
        apply(prev)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    #if os(macOS)
    private func refreshAvailableDisplays() {
        availableDisplayTargets = NSScreen.screens.compactMap { screen in
            guard let screenID = screenID(for: screen) else { return nil }
            let frame = screen.frame
            let width = Int(frame.width)
            let height = Int(frame.height)
            return DisplayTarget(
                id: screenID,
                name: screen.localizedName,
                resolutionText: "\(width)x\(height)",
                isMain: screen == NSScreen.main
            )
        }
    }

    private func savedStartupDisplayID() -> UInt32? {
        let defaults = UserDefaults.standard
        guard let value = defaults.object(forKey: startupDisplaySelectionKey) as? NSNumber else { return nil }
        return value.uint32Value
    }

    private var savedStartupDisplayDescription: String {
        guard let savedID = savedStartupDisplayID() else {
            return "ninguna"
        }
        if let target = availableDisplayTargets.first(where: { $0.id == savedID }) {
            return "\(target.name) (\(target.resolutionText))"
        }
        return "id \(savedID)"
    }

    private func applySavedStartupDisplaySelectionIfNeeded(remainingRetries: Int = 12) {
        guard let savedScreenID = savedStartupDisplayID() else {
            showStartupScreenPicker = true
            return
        }
        guard availableDisplayTargets.contains(where: { $0.id == savedScreenID }) else {
            showStartupScreenPicker = true
            return
        }

        showStartupScreenPicker = false

        guard hostWindow != nil else {
            guard remainingRetries > 0 else {
                showStartupScreenPicker = true
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                applySavedStartupDisplaySelectionIfNeeded(remainingRetries: remainingRetries - 1)
            }
            return
        }

        moveToDisplayAndApplyPresentation(savedScreenID)
    }

    private func forgetSavedStartupDisplaySelection() {
        UserDefaults.standard.removeObject(forKey: startupDisplaySelectionKey)
        refreshAvailableDisplays()
    }

    private func screenID(for screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    private func moveToDisplayAndApplyPresentation(_ targetScreenID: UInt32) {
        guard let window = hostWindow else { return }
        guard let targetScreen = NSScreen.screens.first(where: { screenID(for: $0) == targetScreenID }) else { return }

        window.setFrame(targetScreen.frame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        showStartupScreenPicker = false
        UserDefaults.standard.set(Int(targetScreenID), forKey: startupDisplaySelectionKey)
        applyWindowPresentation(window: window, fullscreen: preferredFullscreen)
    }

    private func ensureFullscreen(window: NSWindow, remainingRetries: Int) {
        guard remainingRetries > 0 else { return }
        if window.styleMask.contains(.fullScreen) { return }

        window.toggleFullScreen(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ensureFullscreen(window: window, remainingRetries: remainingRetries - 1)
        }
    }

    private func ensureWindowed(window: NSWindow, remainingRetries: Int) {
        guard remainingRetries > 0 else { return }
        if window.styleMask.contains(.fullScreen) == false { return }

        window.toggleFullScreen(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ensureWindowed(window: window, remainingRetries: remainingRetries - 1)
        }
    }

    private func applyWindowPresentation(window: NSWindow, fullscreen: Bool) {
        if fullscreen {
            ensureFullscreen(window: window, remainingRetries: 8)
        } else {
            ensureWindowed(window: window, remainingRetries: 8)
        }
    }

    private func setPreferredFullscreen(_ fullscreen: Bool) {
        preferredFullscreen = fullscreen
        saveModeVisibilitySettings()
        guard let window = hostWindow else { return }
        applyWindowPresentation(window: window, fullscreen: fullscreen)
    }

    private func refreshAudioDeviceName() {
        selectedAudioDeviceName = currentDefaultOutputDeviceName() ?? L10n.noAudioDevice
    }

    private func currentDefaultOutputDeviceName() -> String? {
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

    private func refreshCPUUsage() {
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

    private func refreshRunningAppsUsage() {
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

    private func refreshRunningProcessesUsage() {
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

    private func cpuAndCommandByPID() -> [pid_t: (cpuPercent: Double, command: String)] {
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

    private func runPS(arguments: [String]) -> String? {
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

    private func cpuUsageByPID() -> [pid_t: Double] {
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

    private var memoryUsageText: String {
        let usedText = USBVolumeMonitor.compactByteString(memoryUsedBytes)
        let totalText = USBVolumeMonitor.compactByteString(memoryTotalBytes)
        return String(format: "RAM %.1f%%  %@/%@", memoryUsagePercent, usedText, totalText)
    }

    private func refreshMemoryUsage() {
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

    private func startHousekeepingTimer() {
        stopHousekeepingTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                refreshSystemAudioState(triggerOnMuteTransition: true)
                if utilityMode == .audio {
                    refreshAudioDeviceName()
                } else if utilityMode == .cpu {
                    refreshCPUUsage()
                } else if utilityMode == .apps {
                    refreshRunningAppsUsage()
                } else if utilityMode == .processes {
                    refreshRunningProcessesUsage()
                }
            }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        housekeepingTimer = timer
    }

    private func stopHousekeepingTimer() {
        housekeepingTimer?.invalidate()
        housekeepingTimer = nil
    }

    private func refreshSystemAudioState(triggerOnMuteTransition: Bool) {
        if let scalar = currentSystemVolumeScalar() {
            systemVolumePercent = max(0, min(100, Double(scalar) * 100))
        }

        let isMuted = currentSystemMuted() ?? (systemVolumePercent <= 0.0001)
        if let previous = lastKnownSystemMuted,
           previous == false,
           isMuted == true,
           triggerOnMuteTransition {
            if enabledUtilityModes.contains(.volume) {
                utilityMode = .volume
                triggerFlash()
            }
        }
        lastKnownSystemMuted = isMuted
    }

    private func adjustSystemVolumeFromScroll(deltaY: CGFloat) {
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

    private func defaultOutputDeviceID() -> AudioDeviceID? {
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

    private func currentSystemVolumeScalar() -> Float32? {
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

    private func currentSystemMuted() -> Bool? {
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

    private func setSystemVolumeScalar(_ scalar: Float32) -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }
        let clamped = max(0, min(1, scalar))

        if setDeviceVolumeScalar(deviceID: deviceID, element: kAudioObjectPropertyElementMain, value: clamped) {
            return true
        }

        let leftSet = setDeviceVolumeScalar(deviceID: deviceID, element: 1, value: clamped)
        let rightSet = setDeviceVolumeScalar(deviceID: deviceID, element: 2, value: clamped)
        return leftSet || rightSet
    }

    private func getDeviceVolumeScalar(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Float32? {
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

    private func setDeviceVolumeScalar(deviceID: AudioDeviceID, element: AudioObjectPropertyElement, value: Float32) -> Bool {
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

    private func getDeviceMute(deviceID: AudioDeviceID, element: AudioObjectPropertyElement) -> Bool? {
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

    private func startCountdownAlarm() {
        startGlobalAlarm(duration: 30)
    }

    private func startGlobalAlarm(duration: TimeInterval) {
        stopMetronome()
        tunerEngine.stop()
        deactivatePongMode()
        deactivateArkanoidMode()
        deactivateMissileCommandMode()
        deactivateSnakeMode()
        deactivateTodayInHistoryMode()
        deactivateMusicThoughtMode()
        stopCountdownAlarmIfNeeded()
        countdownAlarmActive = true
        preAlarmTopMode = topMode
        preAlarmUtilityMode = utilityMode

        if startBundledAlarmAudioIfAvailable() == false {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.85, repeats: true) { _ in
                NSSound.beep()
            }
            RunLoop.main.add(timer, forMode: .common)
            countdownAlarmTimer = timer
        }

        let stopWork = DispatchWorkItem {
            stopCountdownAlarmIfNeeded()
        }
        countdownAlarmStopWorkItem = stopWork
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: stopWork)

        let flashTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            triggerFlash()
        }
        RunLoop.main.add(flashTimer, forMode: .common)
        countdownAlarmFlashTimer = flashTimer
    }

    private func stopCountdownAlarmIfNeeded(restorePreviousModes: Bool = false) {
        guard countdownAlarmActive else { return }
        countdownAlarmActive = false
        countdownAlarmTimer?.invalidate()
        countdownAlarmTimer = nil
        countdownAlarmFlashTimer?.invalidate()
        countdownAlarmFlashTimer = nil
        countdownAlarmPlayer?.stop()
        countdownAlarmPlayer = nil
        countdownAlarmStopWorkItem?.cancel()
        countdownAlarmStopWorkItem = nil

        if restorePreviousModes {
            alarmEnabled = false
            if let previousTopMode = preAlarmTopMode {
                topMode = previousTopMode
            }
            if let previousUtilityMode = preAlarmUtilityMode {
                if utilityMode != previousUtilityMode {
                    utilityMode = previousUtilityMode
                } else if previousUtilityMode == .pong {
                    activatePongMode()
                }
            }
        }
        preAlarmTopMode = nil
        preAlarmUtilityMode = nil
    }

    private func startBundledAlarmAudioIfAvailable() -> Bool {
        let bundle = Bundle.main
        let url = bundle.url(forResource: "alarma", withExtension: "mp3", subdirectory: "Assets")
            ?? bundle.url(forResource: "alarma", withExtension: "mp3")

        guard let url else { return false }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            countdownAlarmPlayer = player
            return true
        } catch {
            countdownAlarmPlayer = nil
            return false
        }
    }

    private func startMetronome() {
        guard metronomeRunning == false else { return }
        metronomeRunning = true
        metronomeBeatIndex = 0
        triggerMetronomePulse()
        restartMetronomeTimer()
    }

    private func stopMetronome() {
        metronomeRunning = false
        metronomePulseActive = false
        metronomeBeatIndex = 0
        metronomeTimer?.setEventHandler {}
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }

    private func restartMetronomeTimer() {
        metronomeTimer?.setEventHandler {}
        metronomeTimer?.cancel()
        metronomeTimer = nil

        let bpm = Double(max(20, metronomeBPM))
        let beatUnitFactor = 4.0 / Double(metronomeDenominator)
        let interval = max(0.03, (60.0 / bpm) * beatUnitFactor)
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(4))
        timer.setEventHandler {
            DispatchQueue.main.async {
                guard metronomeRunning else { return }
                triggerMetronomePulse()
            }
        }
        timer.resume()
        metronomeTimer = timer
    }

    private func triggerMetronomePulse() {
        let isStrongBeat = metronomeBeatIndex == 0
        metronomeBeatIndex = (metronomeBeatIndex + 1) % max(1, metronomeNumerator)
        metronomePulseActive = true
        playMetronomeTickSound(strong: isStrongBeat)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            metronomePulseActive = false
        }
    }

    private func playMetronomeTickSound(strong: Bool) {
        if metronomeTickPlayer == nil || metronomeStrongTickPlayer == nil {
            prepareMetronomeTickPlayersIfNeeded()
        }

        if strong, let strongPlayer = metronomeStrongTickPlayer {
            strongPlayer.currentTime = 0
            strongPlayer.play()
            return
        }

        if let player = metronomeTickPlayer {
            player.currentTime = 0
            player.play()
            return
        }

        if let fallback = NSSound(named: strong ? "Hero" : "Pop") {
            fallback.play()
        } else {
            NSSound.beep()
        }
    }

    private func prepareMetronomeTickPlayersIfNeeded() {
        let bundle = Bundle.main
        let weakURL = bundle.url(forResource: "tic_seco", withExtension: "wav", subdirectory: "Assets")
            ?? bundle.url(forResource: "tic_seco", withExtension: "wav")
            ?? bundle.url(forResource: "tic", withExtension: "mp3", subdirectory: "Assets")
            ?? bundle.url(forResource: "tic", withExtension: "mp3")
            ?? bundle.url(forResource: "metronomo", withExtension: "mp3", subdirectory: "Assets")
            ?? bundle.url(forResource: "metronomo", withExtension: "mp3")
        let strongURL = bundle.url(forResource: "tic_fuerte", withExtension: "mp3", subdirectory: "Assets")
            ?? bundle.url(forResource: "tic_fuerte", withExtension: "mp3")

        if metronomeTickPlayer == nil, let weakURL {
            do {
                let player = try AVAudioPlayer(contentsOf: weakURL)
                player.numberOfLoops = 0
                player.prepareToPlay()
                metronomeTickPlayer = player
            } catch {
                metronomeTickPlayer = nil
            }
        }

        if metronomeStrongTickPlayer == nil, let strongURL {
            do {
                let player = try AVAudioPlayer(contentsOf: strongURL)
                player.numberOfLoops = 0
                player.prepareToPlay()
                metronomeStrongTickPlayer = player
            } catch {
                metronomeStrongTickPlayer = nil
            }
        }
    }

    private func chooseSeriesFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = L10n.start

        if panel.runModal() == .OK, let selected = panel.url {
            releaseSeriesSecurityScope()
            if selected.startAccessingSecurityScopedResource() {
                seriesSecurityScopeURL = selected
            }
            seriesRootURL = selected
            seriesVideoURLs = discoverSeriesVideos(in: selected)
            seriesResumeVideoURL = nil
            stopSeriesPlaybackByUser()
            seriesResumeVideoURL = nil
        }
    }

    private func discoverSeriesVideos(in root: URL) -> [URL] {
        let allowedExtensions: Set<String> = ["mp4", "mov", "m4v", "mkv", "avi"]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            urls.append(fileURL)
        }
        return urls
    }

    private func playRandomSeriesVideo(excluding excluded: Set<URL> = []) {
        guard seriesVideoURLs.isEmpty == false else {
            seriesCurrentVideoURL = nil
            seriesItemStatusObserver = nil
            seriesStatusText = nil
            seriesPlayer.replaceCurrentItem(with: nil)
            return
        }

        var candidates = seriesVideoURLs.filter { excluded.contains($0) == false }
        if let current = seriesCurrentVideoURL, candidates.count > 1 {
            candidates.removeAll { $0 == current }
        }

        guard let selected = candidates.randomElement() else {
            seriesCurrentVideoURL = nil
            seriesItemStatusObserver = nil
            seriesStatusText = nil
            seriesPlayer.replaceCurrentItem(with: nil)
            return
        }
        playSeriesVideo(selected, excluded: excluded)
    }

    private func stopSeriesPlaybackToFolderSelector() {
        seriesPlayer.pause()
        seriesTranscodeWorkItem?.cancel()
        seriesTranscodeWorkItem = nil
        seriesCurrentVideoURL = nil
        seriesItemStatusObserver = nil
        seriesStatusText = nil
        seriesPlayer.replaceCurrentItem(with: nil)
    }

    private func releaseSeriesSecurityScope() {
        if let scopedURL = seriesSecurityScopeURL {
            scopedURL.stopAccessingSecurityScopedResource()
        }
        seriesSecurityScopeURL = nil
    }

    private func playSeriesVideo(_ sourceURL: URL, excluded: Set<URL>) {
        seriesPlayRequestID += 1
        let requestID = seriesPlayRequestID
        seriesCurrentVideoURL = sourceURL
        seriesItemStatusObserver = nil
        seriesTranscodeWorkItem?.cancel()
        seriesTranscodeWorkItem = nil

        if let prepared = preparedPlayableURL(for: sourceURL) {
            seriesStatusText = nil
            loadSeriesPlayerItem(prepared, sourceURL: sourceURL, excluded: excluded, requestID: requestID)
            return
        }

        guard requiresTranscoding(sourceURL) else {
            seriesStatusText = nil
            loadSeriesPlayerItem(sourceURL, sourceURL: sourceURL, excluded: excluded, requestID: requestID)
            return
        }

        guard let ffmpegPath = findFFmpegPath() else {
            if requiresTranscoding(sourceURL) {
                seriesStatusText = "instalando ffmpeg..."
                attemptAutoInstallFFmpeg { installed in
                    if installed {
                        seriesStatusText = nil
                        guard utilityMode == .series else { return }
                        guard seriesPlayRequestID == requestID else { return }
                        playSeriesVideo(sourceURL, excluded: excluded)
                    } else {
                        seriesStatusText = "ffmpeg no encontrado"
                        var nextExcluded = excluded
                        nextExcluded.insert(sourceURL)
                        playRandomSeriesVideo(excluding: nextExcluded)
                    }
                }
                return
            }
            seriesStatusText = nil
            loadSeriesPlayerItem(sourceURL, sourceURL: sourceURL, excluded: excluded, requestID: requestID)
            return
        }

        seriesStatusText = "convirtiendo 0% · faltan --:--"
        let work = DispatchWorkItem {
            guard let outputURL = transcodeSeriesVideoToMP4(
                sourceURL: sourceURL,
                ffmpegPath: ffmpegPath,
                progress: { percent, remaining in
                    DispatchQueue.main.async {
                        guard seriesPlayRequestID == requestID else { return }
                        let clamped = max(0, min(99, percent))
                        seriesStatusText = "convirtiendo \(clamped)% · faltan \(formatDuration(remaining))"
                    }
                }
            ) else {
                DispatchQueue.main.async {
                    guard seriesPlayRequestID == requestID else { return }
                    seriesStatusText = "error ffmpeg"
                    loadSeriesPlayerItem(sourceURL, sourceURL: sourceURL, excluded: excluded, requestID: requestID)
                }
                return
            }

            DispatchQueue.main.async {
                guard seriesPlayRequestID == requestID else { return }
                seriesPreparedURLs[sourceURL] = outputURL
                seriesStatusText = nil
                loadSeriesPlayerItem(outputURL, sourceURL: sourceURL, excluded: excluded, requestID: requestID)
            }
        }
        seriesTranscodeWorkItem = work
        DispatchQueue.global(qos: .userInitiated).async(execute: work)
    }

    private func loadSeriesPlayerItem(_ playableURL: URL, sourceURL: URL, excluded: Set<URL>, requestID: Int) {
        let item = AVPlayerItem(url: playableURL)
        seriesItemStatusObserver = item.observe(\.status, options: [.new]) { _, _ in
            DispatchQueue.main.async {
                guard utilityMode == .series else { return }
                guard seriesPlayRequestID == requestID else { return }
                if item.status == .failed {
                    if playableURL != sourceURL {
                        seriesPreparedURLs.removeValue(forKey: sourceURL)
                    }
                    var nextExcluded = excluded
                    nextExcluded.insert(sourceURL)
                    playRandomSeriesVideo(excluding: nextExcluded)
                } else if item.status == .readyToPlay {
                    seriesStatusText = nil
                    seriesPlayer.play()
                }
            }
        }
        seriesPlayer.replaceCurrentItem(with: item)
    }

    private func requiresTranscoding(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "mkv" || ext == "avi"
    }

    private func preparedPlayableURL(for sourceURL: URL) -> URL? {
        guard let cached = seriesPreparedURLs[sourceURL] else { return nil }
        return FileManager.default.fileExists(atPath: cached.path) ? cached : nil
    }

    private func findFFmpegPath() -> String? {
        var candidates = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        candidates.append(contentsOf: ffmpegCellarCandidates(base: "/opt/homebrew/Cellar/ffmpeg"))
        candidates.append(contentsOf: ffmpegCellarCandidates(base: "/usr/local/Cellar/ffmpeg"))
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    private func ffmpegCellarCandidates(base: String) -> [String] {
        let fm = FileManager.default
        guard let versions = try? fm.contentsOfDirectory(atPath: base) else { return [] }
        return versions
            .sorted(by: >)
            .map { "\(base)/\($0)/bin/ffmpeg" }
    }

    private func attemptAutoInstallFFmpeg(completion: @escaping (Bool) -> Void) {
        if findFFmpegPath() != nil {
            completion(true)
            return
        }
        if ffmpegInstallInProgress {
            completion(false)
            return
        }
        if ffmpegInstallAttempted {
            completion(false)
            return
        }
        ffmpegInstallAttempted = true
        ffmpegInstallInProgress = true

        let brewPath = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"].first(where: {
            FileManager.default.isExecutableFile(atPath: $0)
        }) ?? "/usr/bin/env"

        let process = Process()
        if brewPath == "/usr/bin/env" {
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["brew", "install", "ffmpeg"]
        } else {
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "ffmpeg"]
        }
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    ffmpegInstallInProgress = false
                    completion(false)
                }
                return
            }

            DispatchQueue.main.async {
                ffmpegInstallInProgress = false
                completion(process.terminationStatus == 0 && findFFmpegPath() != nil)
            }
        }
    }

    private func transcodeSeriesVideoToMP4(
        sourceURL: URL,
        ffmpegPath: String,
        progress: @escaping (_ percent: Int, _ remainingSeconds: TimeInterval) -> Void
    ) -> URL? {
        let cacheDir = seriesCacheDirectoryURL()
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let outputName = "series_\(abs(sourceURL.path.hashValue)).mp4"
        let outputURL = cacheDir.appendingPathComponent(outputName)
        let totalDuration = mediaDurationSeconds(sourceURL, ffmpegPath: ffmpegPath)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        let outPipe = Pipe()
        var pending = ""
        process.arguments = [
            "-y",
            "-i", sourceURL.path,
            "-c:v", "h264",
            "-c:a", "aac",
            "-movflags", "+faststart",
            "-progress", "pipe:2",
            "-nostats",
            outputURL.path
        ]
        process.standardOutput = Pipe()
        process.standardError = outPipe

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard data.isEmpty == false else { return }
            guard var chunk = String(data: data, encoding: .utf8) else { return }
            chunk = chunk.replacingOccurrences(of: "\r", with: "\n")
            pending += chunk

            while let newline = pending.firstIndex(of: "\n") {
                let line = String(pending[..<newline]).trimmingCharacters(in: .whitespacesAndNewlines)
                pending.removeSubrange(...newline)
                if line.hasPrefix("out_time_ms="), let value = Double(line.dropFirst("out_time_ms=".count)) {
                    let outSeconds = value / 1_000_000.0
                    let ratio = totalDuration > 0 ? max(0, min(1, outSeconds / totalDuration)) : 0
                    let percent = Int((ratio * 100.0).rounded())
                    let remaining = totalDuration > 0 ? max(0, totalDuration - outSeconds) : 0
                    progress(percent, remaining)
                } else if line.hasPrefix("out_time_us="), let value = Double(line.dropFirst("out_time_us=".count)) {
                    let outSeconds = value / 1_000_000.0
                    let ratio = totalDuration > 0 ? max(0, min(1, outSeconds / totalDuration)) : 0
                    let percent = Int((ratio * 100.0).rounded())
                    let remaining = totalDuration > 0 ? max(0, totalDuration - outSeconds) : 0
                    progress(percent, remaining)
                }
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            return nil
        }
        outPipe.fileHandleForReading.readabilityHandler = nil
        guard process.terminationStatus == 0 else { return nil }
        return FileManager.default.fileExists(atPath: outputURL.path) ? outputURL : nil
    }

    private func seriesCacheDirectoryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("UtilClockSeriesCache", isDirectory: true)
    }

    private func clearSeriesCacheOnLaunch() {
        let cacheDir = seriesCacheDirectoryURL()
        let fm = FileManager.default
        if fm.fileExists(atPath: cacheDir.path) {
            try? fm.removeItem(at: cacheDir)
        }
        seriesPreparedURLs.removeAll()
    }

    private func mediaDurationSeconds(_ url: URL, ffmpegPath: String) -> TimeInterval {
        if let ffprobeDuration = probeDurationWithFFprobe(url: url, ffmpegPath: ffmpegPath), ffprobeDuration > 0 {
            return ffprobeDuration
        }

        let asset = AVURLAsset(url: url)
        var loadedDuration: CMTime?
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            loadedDuration = try? await asset.load(.duration)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2.0)
        let seconds = CMTimeGetSeconds(loadedDuration ?? .invalid)
        if seconds.isFinite, seconds > 0 {
            return seconds
        }
        return 0
    }

    private func probeDurationWithFFprobe(url: URL, ffmpegPath: String) -> TimeInterval? {
        let ffprobePath = (ffmpegPath as NSString).deletingLastPathComponent + "/ffprobe"
        guard FileManager.default.isExecutableFile(atPath: ffprobePath) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            url.path
        ]
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              let value = Double(text),
              value.isFinite,
              value > 0 else {
            return nil
        }
        return value
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds.rounded()))
        let mins = value / 60
        let secs = value % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func stopSeriesPlaybackByUser() {
        seriesTranscodeWorkItem?.cancel()
        seriesTranscodeWorkItem = nil
        seriesStatusText = nil
        seriesResumeVideoURL = seriesCurrentVideoURL
        seriesCurrentVideoURL = nil
        seriesItemStatusObserver = nil
        seriesPlayer.pause()
    }

    private func startSeriesPlaybackByUser() {
        if seriesPlayer.currentItem != nil, seriesResumeVideoURL != nil {
            seriesCurrentVideoURL = seriesResumeVideoURL
            seriesPlayer.play()
            return
        }
        seriesResumeVideoURL = nil
        playRandomSeriesVideo()
    }

    private func installFullscreenDoubleClickMonitorIfNeeded() {
        guard fullscreenDoubleClickMonitor == nil else { return }
        fullscreenDoubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            guard event.clickCount > 1 else { return event }
            guard let eventWindow = event.window, let hostWindow else { return event }
            guard eventWindow == hostWindow else { return event }
            return nil
        }
    }

    private func removeFullscreenDoubleClickMonitor() {
        guard let monitor = fullscreenDoubleClickMonitor else { return }
        NSEvent.removeMonitor(monitor)
        fullscreenDoubleClickMonitor = nil
    }

    private func installSeriesEscapeKeyMonitorIfNeeded() {
        guard seriesEscapeKeyMonitor == nil else { return }
        seriesEscapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard utilityMode == .series else { return event }
            // ESC key
            if event.keyCode == 53 {
                stopSeriesPlaybackToFolderSelector()
                return nil
            }
            return event
        }
    }

    private func removeSeriesEscapeKeyMonitor() {
        guard let monitor = seriesEscapeKeyMonitor else { return }
        NSEvent.removeMonitor(monitor)
        seriesEscapeKeyMonitor = nil
    }
    #endif

    #if os(macOS)
    private func triggerFlash() {
        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = 0.96
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.easeIn(duration: 0.22)) {
                flashOpacity = 0
            }
        }
    }
    #endif
}

#if os(macOS)
private struct SeriesPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        view.showsFullScreenToggleButton = false
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
        nsView.videoGravity = .resizeAspectFill
        nsView.controlsStyle = .none
    }
}
#endif

private struct PressableCountdownButtonStyle: ButtonStyle {
    let phosphorColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? phosphorColor.opacity(0.22) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.15 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

#if os(macOS)
private struct MouseClickCatcher: NSViewRepresentable {
    let onLeftClick: () -> Void
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> RepeatClickNSView {
        let view = RepeatClickNSView()
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: RepeatClickNSView, context: Context) {
        nsView.onLeftClick = onLeftClick
        nsView.onRightClick = onRightClick
    }
}

private final class RepeatClickNSView: NSView {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    private enum ActiveButton {
        case left
        case right
    }

    private let holdDelay: TimeInterval = 0.28
    private let repeatInterval: TimeInterval = 0.055
    private var activeButton: ActiveButton?
    private var holdScheduledButton: ActiveButton?
    private var repeatTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    deinit {
        stopRepeat()
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func mouseDown(with event: NSEvent) {
        beginPress(.left)
    }

    override func mouseUp(with event: NSEvent) {
        endPress(.left)
    }

    override func rightMouseDown(with event: NSEvent) {
        beginPress(.right)
    }

    override func rightMouseUp(with event: NSEvent) {
        endPress(.right)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            stopRepeat()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    private func beginPress(_ button: ActiveButton) {
        activeButton = button
        holdScheduledButton = button
        fire(button)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginRepeatIfStillPressed), object: nil)
        perform(#selector(beginRepeatIfStillPressed), with: nil, afterDelay: holdDelay)
    }

    private func endPress(_ button: ActiveButton) {
        guard activeButton == button else { return }
        stopRepeat()
    }

    private func startRepeat(_ button: ActiveButton) {
        guard activeButton == button else { return }
        repeatTimer?.invalidate()
        repeatTimer = Timer(timeInterval: repeatInterval, target: self, selector: #selector(repeatTick), userInfo: nil, repeats: true)
        if let repeatTimer {
            RunLoop.main.add(repeatTimer, forMode: .common)
        }
    }

    @objc
    private func beginRepeatIfStillPressed() {
        guard let button = holdScheduledButton, activeButton == button else { return }
        startRepeat(button)
    }

    @objc
    private func repeatTick() {
        guard let button = activeButton else {
            stopRepeat()
            return
        }
        fire(button)
    }

    private func stopRepeat() {
        activeButton = nil
        holdScheduledButton = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginRepeatIfStillPressed), object: nil)
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    private func fire(_ button: ActiveButton) {
        switch button {
        case .left:
            onLeftClick?()
        case .right:
            onRightClick?()
        }
    }
}

private struct MouseScrollCatcher: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> ScrollCaptureNSView {
        let view = ScrollCaptureNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollCaptureNSView, context: Context) {
        nsView.onScroll = onScroll
    }
}

private final class ScrollCaptureNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.scrollingDeltaY)
    }
}

private struct MouseTrackingCatcher: NSViewRepresentable {
    let onMove: (CGPoint) -> Void
    let onLeftClick: (CGPoint) -> Void
    let onRightClick: (CGPoint) -> Void

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let view = MouseTrackingNSView()
        view.onMove = onMove
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMove = onMove
        nsView.onLeftClick = onLeftClick
        nsView.onRightClick = onRightClick
    }
}

private final class MouseTrackingNSView: NSView {
    var onMove: ((CGPoint) -> Void)?
    var onLeftClick: ((CGPoint) -> Void)?
    var onRightClick: ((CGPoint) -> Void)?
    private var trackingAreaRef: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        window?.acceptsMouseMovedEvents = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        window?.acceptsMouseMovedEvents = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingAreaRef {
            removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func mouseMoved(with event: NSEvent) {
        onMove?(convert(event.locationInWindow, from: nil))
    }

    override func mouseDown(with event: NSEvent) {
        onLeftClick?(convert(event.locationInWindow, from: nil))
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(convert(event.locationInWindow, from: nil))
    }
}
#endif

private struct DiskPieChart: View {
    let usedBytes: Int64
    let freeBytes: Int64

    private var total: Double {
        max(0, Double(usedBytes + freeBytes))
    }

    private var usedFraction: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, Double(usedBytes) / total))
    }

    private var freeFraction: Double {
        1 - usedFraction
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let startAngle = -90.0

            ZStack {
                Circle()
                    .fill(Color(red: 0.05, green: 0.16, blue: 0.09))

                PieSliceShape(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + (360 * usedFraction))
                )
                .fill(Color(red: 0.2, green: 0.45, blue: 0.28))

                PieSliceShape(
                    startAngle: .degrees(startAngle + (360 * usedFraction)),
                    endAngle: .degrees(startAngle + (360 * (usedFraction + freeFraction)))
                )
                .fill(Color(red: 0.64, green: 1.0, blue: 0.75))

                Circle()
                    .stroke(Color(red: 0.64, green: 1.0, blue: 0.75).opacity(0.6), lineWidth: max(1, size * 0.04))
            }
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
        }
    }
}

private struct CRTScanlines: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                var path = Path()
                let spacing: CGFloat = 3
                var y: CGFloat = 0

                while y < size.height {
                    path.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                    y += spacing
                }

                context.fill(path, with: .color(Color.black.opacity(0.22)))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#if os(macOS)
private struct WindowReader: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.window = nsView.window
        }
    }
}
#endif

#Preview {
    ContentView()
}
