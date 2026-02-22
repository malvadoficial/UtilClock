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
import QuartzCore
import ServiceManagement
import UniformTypeIdentifiers
#endif

struct ContentView: View {
    #if os(macOS)
    let gameLoopIntervalMs = 16
    let gameLoopLeewayMs = 4
    let startupDisplaySelectionKey = "utilclock.startup.selectedDisplayID"
    #endif
    let preferredFullscreenKey = "utilclock.window.preferredFullscreen"
    let menuBarOnlyModeKey = "utilclock.presentation.menuBarOnly"

    #if os(macOS)
    struct DisplayTarget: Identifiable {
        let id: UInt32
        let name: String
        let resolutionText: String
        let isMain: Bool
    }
    #endif

    enum TopClockMode: CaseIterable, Hashable {
        case clock
        case worldClock
        case calendar
        case weather
        case uptime
        case stopwatch
        case countdown
        case alarm

        var key: String {
            switch self {
            case .clock: return "clock"
            case .worldClock: return "worldClock"
            case .calendar: return "calendar"
            case .weather: return "weather"
            case .uptime: return "uptime"
            case .stopwatch: return "stopwatch"
            case .countdown: return "countdown"
            case .alarm: return "alarm"
            }
        }

        var next: TopClockMode {
            switch self {
            case .clock: return .worldClock
            case .worldClock: return .calendar
            case .calendar: return .weather
            case .weather: return .uptime
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
            case .calendar: return .worldClock
            case .weather: return .calendar
            case .uptime: return .weather
            case .stopwatch: return .uptime
            case .countdown: return .stopwatch
            case .alarm: return .countdown
            }
        }
    }

    enum UtilityMode: CaseIterable, Hashable {
        case audio
        case storage
        case network
        case cpu
        case apps
        case music
        case games
        case info

        var key: String {
            switch self {
            case .audio: return "audio"
            case .storage: return "storage"
            case .network: return "network"
            case .cpu: return "cpu"
            case .apps: return "apps"
            case .music: return "music"
            case .games: return "games"
            case .info: return "info"
            }
        }

        var next: UtilityMode {
            switch self {
            case .audio: return .storage
            case .storage: return .network
            case .network: return .cpu
            case .cpu: return .apps
            case .apps: return .music
            case .music: return .games
            case .games: return .info
            case .info: return .audio
            }
        }

        var previous: UtilityMode {
            switch self {
            case .audio: return .info
            case .storage: return .audio
            case .network: return .storage
            case .cpu: return .network
            case .apps: return .cpu
            case .music: return .apps
            case .games: return .music
            case .info: return .games
            }
        }
    }

    enum AppsMonitorMode: String, CaseIterable, Hashable {
        case apps
        case processes
    }

    enum MusicMode: String, CaseIterable, Hashable {
        case tuner
        case chordFinder
        case chordDetect
        case metronome
    }

    enum InfoMode: String, CaseIterable, Hashable {
        case todayInHistory
        case musicThought
        case rae
    }

    enum GameMode: String, CaseIterable, Hashable {
        case pong
        case arkanoid
        case missileCommand
        case snake
        case chromeDino
        case tetris
        case spaceInvaders
        case asteroids
        case tron
        case pacman
        case frogger
        case artillery
    }

    enum SplitFullscreenTarget: Hashable {
        case none
        case top
        case bottom
    }

    struct ChordVoicing: Identifiable {
        let id: String
        let frets: [Int]
        let fingers: [Int]
    }

    struct ParsedChord {
        let symbol: String
        let lookupKey: String
        let rootPitchClass: Int
        let pitchClasses: Set<Int>
    }

    struct ThisDayEvent: Identifiable {
        let id: String
        let month: Int
        let day: Int
        let year: Int
        let es: String
        let en: String
    }

    #if os(macOS)
    struct RunningAppUsage: Identifiable {
        let id: Int32
        let name: String
        let cpuPercent: Double
        let icon: NSImage
    }

    struct RunningProcessUsage: Identifiable {
        let id: Int32
        let name: String
        let cpuPercent: Double
    }

    struct TopModeDropDelegate: DropDelegate {
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

    struct UtilityModeDropDelegate: DropDelegate {
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

    enum MissileTargetKind {
        case city(Int)
        case base(Int)
    }

    struct MissileEnemy: Identifiable {
        let id = UUID()
        let start: CGPoint
        let target: CGPoint
        let targetKind: MissileTargetKind
        var position: CGPoint
        var velocity: CGVector
    }

    struct MissilePlayerRocket: Identifiable {
        let id = UUID()
        let start: CGPoint
        let target: CGPoint
        var position: CGPoint
        var velocity: CGVector
    }

    struct MissileExplosion: Identifiable {
        let id = UUID()
        let center: CGPoint
        var age: CGFloat
        let maxAge: CGFloat
        let maxRadius: CGFloat
    }

    enum DinoObstacleKind {
        case stone
        case tree
        case bird
    }

    struct DinoObstacle: Identifiable {
        let id = UUID()
        let kind: DinoObstacleKind
        var x: CGFloat
        var width: CGFloat
        var height: CGFloat
        var groundOffset: CGFloat
    }

    enum TetrisPieceKind: CaseIterable {
        case i
        case o
        case t
        case s
        case z
        case j
        case l
    }

    struct TetrisPieceState {
        var kind: TetrisPieceKind
        var rotation: Int
        var x: Int
        var y: Int
    }

    struct InvaderEnemy: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let type: Int
    }

    struct InvaderBullet: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
    }

    struct AsteroidsRock: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var radius: CGFloat
        var size: Int
    }

    struct AsteroidsProjectile: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var life: CGFloat
    }

    struct FroggerObstacle: Identifiable {
        let id = UUID()
        let lane: Int
        let isLog: Bool
        var x: CGFloat
        var width: CGFloat
        var speed: CGFloat
    }

    struct ArtilleryMountain: Identifiable {
        let id = UUID()
        var leftX: CGFloat
        var rightX: CGFloat
        var peakX: CGFloat
        var peakY: CGFloat
    }

    struct OnThisDayResponse: Decodable {
        struct Entry: Decodable {
            let text: String?
            let year: Int?
        }

        let selected: [Entry]?
        let events: [Entry]?
        let births: [Entry]?
        let deaths: [Entry]?
    }

    struct MusicThoughtQuote: Identifiable, Equatable {
        let id: String
        let quote: String
        let author: String
        let linkPath: String
    }

    enum DisplayPalette: String, CaseIterable {
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

    enum FlashReason {
        case general
        case spaceInvadersPlayerHit
    }

    @StateObject var viewModel = ClockViewModel()
    @State var topMode: TopClockMode = .clock
    @State var utilityMode: UtilityMode = .audio
    @State var displayPalette: DisplayPalette = .green
    @State var showSettings = false
    @State var showQuitAppConfirmation = false
    @State var enabledTopModes: Set<TopClockMode> = Set(TopClockMode.allCases)
    @State var enabledUtilityModes: Set<UtilityMode> = Set(UtilityMode.allCases)
    @State var topModeOrder: [TopClockMode] = TopClockMode.allCases
    @State var utilityModeOrder: [UtilityMode] = UtilityMode.allCases
    @State var countdownSetHours = 0
    @State var countdownSetMinutes = 0
    @State var countdownSetSeconds = 0
    @State var countdownInitialSeconds = 0
    @State var countdownRemainingSeconds = 0
    @State var countdownRunning = false
    @State var stopwatchRunning = false
    @State var stopwatchAccumulatedCentiseconds = 0
    @State var stopwatchStartDate: Date?
    @State var stopwatchPrestartCountdownEnabled = false
    @State var stopwatchPrestartInProgress = false
    @State var stopwatchPrestartDisplayValue: Int?
    @State var stopwatchPrestartTask: Task<Void, Never>?
    @State var alarmSetHours = 0
    @State var alarmSetMinutes = 0
    @State var alarmEnabled = false
    @State var selectedWorldCityIndex = 0
    @State var calendarMonthOffset = 0
    @State var weatherLocationName = "-"
    @State var weatherCurrentTemperatureC: Double?
    @State var weatherCurrentWeatherCode = 0
    @State var weatherCurrentWindKmh: Double?
    @State var weatherTodayMinC: Double?
    @State var weatherTodayMaxC: Double?
    @State var weatherForecastDays: [WeatherDayForecast] = []
    @State var weatherLatitude: Double?
    @State var weatherLongitude: Double?
    @State var weatherLastRefresh: Date?
    @State var weatherLoading = false
    @State var weatherErrorText: String?
    @State var splitFullscreenTarget: SplitFullscreenTarget = .none
    @State var preferredFullscreen = true
    @State var menuBarOnlyMode = false
    @State var launchAtLoginEnabled = false
    @State var launchAtLoginErrorText: String?
    @State var lastTriggeredAlarmSecondKey: String?
    @State var selectedAudioDeviceName = L10n.noAudioDevice
    @State var cpuUsagePercent: Double = 0
    @State var memoryUsagePercent: Double = 0
    @State var memoryUsedBytes: Int64 = 0
    @State var memoryTotalBytes: Int64 = 0
    @State var systemVolumePercent: Double = 0
    @State var metronomeBPM = 120
    @State var metronomeRunning = false
    @State var metronomePulseActive = false
    @State var metronomeBeatIndex = 0
    @State var metronomeNumerator = 4
    @State var metronomeDenominator = 4
    @State var chordInput = "Am"
    @State var chordVoicingIndex = 0
    @State var parsedChord: ParsedChord?
    @State var chordGeneratedVoicings: [ChordVoicing] = []
    @State var selectedMusicMode: MusicMode?
    @State var selectedGameMode: GameMode?
    @State var selectedInfoMode: InfoMode?
    @State var selectedAppsMonitorMode: AppsMonitorMode = .apps
    #if os(macOS)
    @State var draggedTopMode: TopClockMode?
    @State var draggedUtilityMode: UtilityMode?
    @State var hostWindow: NSWindow?
    @State var runningAppsUsage: [RunningAppUsage] = []
    @State var runningProcessesUsage: [RunningProcessUsage] = []
    @StateObject var usbMonitor = USBVolumeMonitor()
    @State var networkPublicIPAddress = "-"
    @State var networkWiFiPrivateIPAddress = "-"
    @State var networkEthernetPrivateIPAddress = "-"
    @State var networkWiFiInterfaceName = "en0"
    @State var networkEthernetInterfaceName = "en1"
    @State var networkWiFiDownloadBytesPerSecond: Double = 0
    @State var networkWiFiUploadBytesPerSecond: Double = 0
    @State var networkEthernetDownloadBytesPerSecond: Double = 0
    @State var networkEthernetUploadBytesPerSecond: Double = 0
    @State var networkLastCounters: [String: (rxBytes: UInt64, txBytes: UInt64)] = [:]
    @State var networkLastSampleDate: Date?
    @State var networkLastPublicIPRefresh: Date?
    @State var networkPublicIPFetchInFlight = false
    @State var networkLastInterfaceRefresh: Date?
    @State var flashOpacity: Double = 0
    @State var knownVolumeIDs: Set<String> = []
    @State var storageInfoPopoverVolumeID: String?
    @State var lastCPUTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?
    @State var lastKnownSystemMuted: Bool?
    @State var countdownAlarmActive = false
    @State var countdownAlarmTimer: Timer?
    @State var countdownAlarmFlashTimer: Timer?
    @State var countdownAlarmStopWorkItem: DispatchWorkItem?
    @State var countdownAlarmPlayer: AVAudioPlayer?
    @State var countdownBeepPlayer: AVAudioPlayer?
    @State var metronomeTickPlayer: AVAudioPlayer?
    @State var metronomeStrongTickPlayer: AVAudioPlayer?
    @State var housekeepingTimer: Timer?
    @StateObject var tunerEngine = TunerEngine()
    @State var preAlarmTopMode: TopClockMode?
    @State var preAlarmUtilityMode: UtilityMode?
    @State var preAlarmMusicMode: MusicMode?
    @State var preAlarmGameMode: GameMode?
    @State var preAlarmInfoMode: InfoMode?
    @State var showStartupScreenPicker = true
    @State var availableDisplayTargets: [DisplayTarget] = []
    @State var metronomeTimer: DispatchSourceTimer?
    @State var fullscreenDoubleClickMonitor: Any?
    @State var pongFieldSizeLevel = 4
    @State var pongRunning = false
    @State var pongPlayerScore = 0
    @State var pongCPUScore = 0
    @State var pongBallPosition = CGPoint(x: 0.5, y: 0.5)
    @State var pongBallVelocity = CGVector(dx: 0.62, dy: 0.16)
    @State var pongPlayerPaddleCenterY: CGFloat = 0.5
    @State var pongPlayerPaddleTargetY: CGFloat = 0.5
    @State var pongAIPaddleCenterY: CGFloat = 0.5
    @State var pongUpPressed = false
    @State var pongDownPressed = false
    @State var pongTimer: DispatchSourceTimer?
    @State var pongKeyboardMonitor: Any?
    @State var pongKeyboardFlagsMonitor: Any?
    @State var arkanoidRunning = false
    @State var arkanoidScore = 0
    @State var arkanoidLives = 3
    @State var arkanoidBallPosition = CGPoint(x: 0.5, y: 0.78)
    @State var arkanoidBallVelocity = CGVector(dx: 0.58, dy: -0.62)
    @State var arkanoidPaddleCenterX: CGFloat = 0.5
    @State var arkanoidLeftPressed = false
    @State var arkanoidRightPressed = false
    @State var arkanoidBrickAlive = Array(repeating: true, count: 40)
    @State var arkanoidPaddleBoostRemaining: CGFloat = 0
    @State var arkanoidHitsSinceBoost = 0
    @State var arkanoidTimer: DispatchSourceTimer?
    @State var arkanoidKeyboardMonitor: Any?
    @State var arkanoidKeyboardFlagsMonitor: Any?
    @State var snakeRunning = false
    @State var snakeScore = 0
    @State var snakeGameOver = false
    @State var snakeBoardSizeLevel = 3
    @State var snakeDirection = CGVector(dx: 1, dy: 0)
    @State var snakePendingDirection = CGVector(dx: 1, dy: 0)
    @State var snakeBody = [SIMD2<Int32>(8, 6), SIMD2<Int32>(7, 6), SIMD2<Int32>(6, 6)]
    @State var snakeFood = SIMD2<Int32>(14, 8)
    @State var snakeLastStepTime: TimeInterval = 0
    @State var snakeStepAccumulator: TimeInterval = 0
    @State var snakeRenderProgress: CGFloat = 1
    @State var snakeTimer: DispatchSourceTimer?
    @State var snakeKeyboardMonitor: Any?
    @State var chromeDinoRunning = false
    @State var chromeDinoGameOver = false
    @State var chromeDinoScore: Double = 0
    @State var chromeDinoJumpHeight: CGFloat = 0
    @State var chromeDinoJumpVelocity: CGFloat = 0
    @State var chromeDinoSpeed: CGFloat = 0.52
    @State var chromeDinoSpawnAccumulator: CGFloat = 0
    @State var chromeDinoObstacles: [DinoObstacle] = []
    @State var chromeDinoTimer: DispatchSourceTimer?
    @State var chromeDinoKeyboardMonitor: Any?
    @State var tetrisRunning = false
    @State var tetrisGameOver = false
    @State var tetrisScore = 0
    @State var tetrisLevel = 1
    @State var tetrisBoard: [[Int]] = Array(repeating: Array(repeating: 0, count: 10), count: 20)
    @State var tetrisCurrentPiece: TetrisPieceState?
    @State var tetrisDropAccumulator: CGFloat = 0
    @State var tetrisTimer: DispatchSourceTimer?
    @State var tetrisKeyboardMonitor: Any?
    @State var tetrisKeyboardUpMonitor: Any?
    @State var tetrisSoftDropPressed = false
    @State var spaceInvadersRunning = false
    @State var spaceInvadersGameOver = false
    @State var spaceInvadersScore = 0
    @State var spaceInvadersWave = 1
    @State var spaceInvadersPlayerX: CGFloat = 0.5
    @State var spaceInvadersMoveLeftPressed = false
    @State var spaceInvadersMoveRightPressed = false
    @State var spaceInvadersFleetDirection: CGFloat = 1
    @State var spaceInvadersEnemies: [InvaderEnemy] = []
    @State var spaceInvadersPlayerBullets: [InvaderBullet] = []
    @State var spaceInvadersEnemyBullets: [InvaderBullet] = []
    @State var spaceInvadersEnemyShotCooldown: CGFloat = 0
    @State var spaceInvadersTimer: DispatchSourceTimer?
    @State var spaceInvadersKeyboardMonitor: Any?
    @State var spaceInvadersKeyboardUpMonitor: Any?
    @State var asteroidsRunning = false
    @State var asteroidsGameOver = false
    @State var asteroidsScore = 0
    @State var asteroidsShipX: CGFloat = 0.5
    @State var asteroidsShipY: CGFloat = 0.5
    @State var asteroidsShipVX: CGFloat = 0
    @State var asteroidsShipVY: CGFloat = 0
    @State var asteroidsShipAngle: CGFloat = -.pi / 2
    @State var asteroidsTurnLeftPressed = false
    @State var asteroidsTurnRightPressed = false
    @State var asteroidsThrustPressed = false
    @State var asteroidsRocks: [AsteroidsRock] = []
    @State var asteroidsBullets: [AsteroidsProjectile] = []
    @State var asteroidsTimer: DispatchSourceTimer?
    @State var asteroidsKeyboardMonitor: Any?
    @State var asteroidsKeyboardUpMonitor: Any?
    @State var tronRunning = false
    @State var tronGameOver = false
    @State var tronScore = 0
    @State var tronCols = 34
    @State var tronRows = 18
    @State var tronPlayerPos = SIMD2<Int>(6, 9)
    @State var tronEnemyPos = SIMD2<Int>(27, 9)
    @State var tronPlayerDir = SIMD2<Int>(1, 0)
    @State var tronEnemyDir = SIMD2<Int>(-1, 0)
    @State var tronTrailKeys: Set<String> = []
    @State var tronTimer: DispatchSourceTimer?
    @State var tronKeyboardMonitor: Any?
    @State var pacmanRunning = false
    @State var pacmanGameOver = false
    @State var pacmanScore = 0
    @State var pacmanCols = 21
    @State var pacmanRows = 15
    @State var pacmanPlayerPos = SIMD2<Int>(10, 11)
    @State var pacmanDirection = SIMD2<Int>(0, 0)
    @State var pacmanPendingDirection = SIMD2<Int>(0, 0)
    @State var pacmanPelletKeys: Set<String> = []
    @State var pacmanPowerPelletKeys: Set<String> = []
    @State var pacmanPoweredRemaining: Int = 0
    @State var pacmanGhosts: [SIMD2<Int>] = []
    @State var pacmanTimer: DispatchSourceTimer?
    @State var pacmanKeyboardMonitor: Any?
    @State var froggerRunning = false
    @State var froggerGameOver = false
    @State var froggerScore = 0
    @State var froggerCols = 11
    @State var froggerRows = 12
    @State var froggerPlayerCol = 5
    @State var froggerPlayerRow = 11
    @State var froggerCarryAccumulator: CGFloat = 0
    @State var froggerObstacles: [FroggerObstacle] = []
    @State var froggerTimer: DispatchSourceTimer?
    @State var froggerKeyboardMonitor: Any?
    @State var artilleryRunning = false
    @State var artilleryScore = 0
    @State var artilleryAngleDeg: CGFloat = 46
    @State var artillerySpeedInput = "72"
    @State var artilleryWindEnabled = false
    @State var artilleryWindX: CGFloat = 0
    @State var artilleryCannonBase = CGPoint(x: 0.11, y: 0.86)
    @State var artilleryCannonFacing: CGFloat = 1
    @State var artilleryProjectileActive = false
    @State var artilleryProjectileX: CGFloat = 0.11
    @State var artilleryProjectileY: CGFloat = 0.86
    @State var artilleryProjectileVX: CGFloat = 0
    @State var artilleryProjectileVY: CGFloat = 0
    @State var artilleryTrail: [CGPoint] = []
    @State var artilleryTarget = CGPoint(x: 0.82, y: 0.50)
    @State var artilleryMountains: [ArtilleryMountain] = []
    @State var artilleryTimer: DispatchSourceTimer?
    @State var artilleryKeyboardMonitor: Any?
    @State var missileRunning = false
    @State var missileGameOver = false
    @State var missileScore = 0
    @State var missileWave = 1
    @State var missileAmmo = 24
    @State var missileSpawnedInWave = 0
    @State var missileWaveQuota = 14
    @State var missileSpawnAccumulator: CGFloat = 0
    @State var missileCities = Array(repeating: true, count: 6)
    @State var missileBases = Array(repeating: true, count: 3)
    @State var missileEnemies: [MissileEnemy] = []
    @State var missilePlayerRockets: [MissilePlayerRocket] = []
    @State var missileExplosions: [MissileExplosion] = []
    @State var missileTargetPoint = CGPoint(x: 0.5, y: 0.42)
    @State var missileTimer: DispatchSourceTimer?
    @State var todayInternetEvents: [ThisDayEvent] = []
    @State var todayEventsRotationOffset = 0
    @State var todayEventsTimer: Timer?
    @State var todayEventsLastRefresh: Date?
    @State var todayEventsLoading = false
    @State var todayEventsInitialLoadCompleted = false
    @State var musicThoughtQuotes: [MusicThoughtQuote] = []
    @State var musicThoughtIndex = 0
    @State var musicThoughtTimer: Timer?
    @State var musicThoughtLoading = false
    @State var musicThoughtLastRefresh: Date?
    @State var raeSearchText = ""
    @State var raeResultLines: [String] = []
    @State var raeSearchRequestID = 0
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
                    VStack(spacing: 0) {
                    VStack(spacing: 2) {
                        if topMode == .calendar {
                            topCalendarView(dateSize: dateSize)
                        } else if topMode == .weather {
                            topWeatherView(dateSize: dateSize, driveTitleSize: driveTitleSize)
                        } else if topMode == .stopwatch {
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
                    .minimumScaleFactor((topMode == .calendar || topMode == .weather) ? 1 : 0.5)
                    .lineLimit((topMode == .calendar || topMode == .weather) ? nil : 1)
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
                            audioUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
                        } else if utilityMode == .music, selectedMusicMode == nil {
                            musicLauncherView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if isMusicActive(.metronome) {
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
                        } else if isMusicActive(.tuner) {
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
                        } else if isMusicActive(.chordDetect) {
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
                        } else if isMusicActive(.chordFinder) {
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
                        } else if utilityMode == .games {
                            gamesView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .info, selectedInfoMode == nil {
                            infoLauncherView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if isInfoActive(.todayInHistory) {
                            todayInHistoryView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if isInfoActive(.musicThought) {
                            musicThoughtView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if isInfoActive(.rae) {
                            raeView
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if utilityMode == .cpu {
                            cpuUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
                        } else if utilityMode == .apps {
                            appsUtilityView(dateSize: dateSize)
                        } else if utilityMode == .network {
                            networkUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
                        } else if utilityMode == .storage {
                            storageUtilityView(rowFontSize: driveTitleSize)
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
                    .overlay(alignment: .topLeading) {
                        if utilityMode == .music, selectedMusicMode != nil {
                            Button(action: {
                                selectedMusicMode = nil
                                syncMusicActivation()
                            }) {
                                Text("volver")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                            .padding(.leading, 10)
                        }
                        if utilityMode == .info, selectedInfoMode != nil {
                            Button(action: {
                                selectedInfoMode = nil
                                syncInfoActivation()
                            }) {
                                Text("volver")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                            .padding(.leading, 10)
                        }
                    }
                    .overlay {
                        if utilityMode == .audio {
                            MouseScrollCatcher { deltaY in
                                adjustSystemVolumeFromScroll(deltaY: deltaY)
                            }
                        }
                    }
                    #endif
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
                if countdownAlarmActive == false, isBottomFullscreen == false {
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
                    let hideUtilityTagInAggregatedSubmode =
                        (utilityMode == .music && selectedMusicMode != nil) ||
                        (utilityMode == .games && selectedGameMode != nil) ||
                        (utilityMode == .info && selectedInfoMode != nil)
                    if hideUtilityTagInAggregatedSubmode == false {
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
            loadModeVisibilitySettings()
            refreshLaunchAtLoginStatus()
            knownVolumeIDs = Set(usbMonitor.volumes.map(\.id))
            syncAlarmToCurrentTimeIfUnset()
            refreshAudioDeviceName()
            refreshCPUUsage()
            refreshSystemAudioState(triggerOnMuteTransition: false)
            refreshNetworkModeData(forcePublicIPRefresh: true)
            startHousekeepingTimer()
            refreshAvailableDisplays()
            applySavedStartupDisplaySelectionIfNeeded()
            syncMusicActivation()
            syncGameActivation()
            syncInfoActivation()
            refreshWeatherDataIfNeeded(force: true)
        }
        .onChange(of: usbMonitor.volumes.map(\.id)) { _, ids in
            let newIDs = Set(ids)
            let addedIDs = newIDs.subtracting(knownVolumeIDs)
            if newIDs != knownVolumeIDs {
                triggerFlash()
            }
            if addedIDs.isEmpty == false {
                if enabledUtilityModes.contains(.storage) {
                    utilityMode = .storage
                }
            }
            knownVolumeIDs = newIDs
        }
        .onChange(of: viewModel.now) { _, _ in
            tickCountdown()
            tickScheduledAlarm(now: viewModel.now)
        }
        .onChange(of: topMode) { _, newMode in
            if newMode == .weather {
                refreshWeatherDataIfNeeded(force: true)
            }
        }
        .onChange(of: utilityMode) { _, newMode in
            if newMode != .music {
                selectedMusicMode = nil
            }
            syncMusicActivation()

            if newMode != .games {
                selectedGameMode = nil
            }
            syncGameActivation()
            if newMode != .info {
                selectedInfoMode = nil
            }
            syncInfoActivation()

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
            deactivateChromeDinoMode()
            deactivateTetrisMode()
            deactivateSpaceInvadersMode()
            deactivateAsteroidsMode()
            deactivateTronMode()
            deactivatePacmanMode()
            deactivateFroggerMode()
            deactivateArtilleryMode()
            deactivateTodayInHistoryMode()
            deactivateMusicThoughtMode()
            stopHousekeepingTimer()
        }
        .onChange(of: selectedGameMode) { _, _ in
            syncGameActivation()
        }
        .onChange(of: selectedMusicMode) { _, _ in
            syncMusicActivation()
        }
        .onChange(of: selectedInfoMode) { _, _ in
            syncInfoActivation()
        }
        #endif
    }

    func displayFont(size: CGFloat, weight: Font.Weight) -> Font {
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

    var phosphorColor: Color {
        displayPalette.color
    }

    var phosphorDim: Color {
        displayPalette.dimColor
    }

    var alarmColor: Color {
        phosphorColor
    }

    var tunerBelowColor: Color {
        Color(red: 1.0, green: 0.88, blue: 0.2)
    }

    var displayedHourMinuteText: String {
        switch topMode {
        case .clock:
            return viewModel.hourMinuteText
        case .worldClock:
            return worldClockHourMinuteText
        case .calendar:
            return viewModel.hourMinuteText
        case .weather:
            return viewModel.hourMinuteText
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

    var displayedHourMinuteParts: (hours: String, minutes: String) {
        let text = displayedHourMinuteText
        guard let separator = text.firstIndex(of: ":") else {
            return (text, "00")
        }
        let hours = String(text[..<separator])
        let minutesStart = text.index(after: separator)
        let minutes = String(text[minutesStart...])
        return (hours, minutes)
    }

    var shouldBlinkTimeSeparator: Bool {
        switch topMode {
        case .clock, .worldClock, .uptime:
            return true
        case .calendar:
            return false
        case .weather:
            return false
        case .stopwatch:
            return stopwatchRunning
        case .countdown:
            return countdownRunning
        case .alarm:
            return false
        }
    }

    var timeSeparatorOpacity: Double {
        guard shouldBlinkTimeSeparator else { return 1.0 }
        let second = Calendar.current.component(.second, from: viewModel.now)
        return second.isMultiple(of: 2) ? 1.0 : 0.18
    }

    var topModeLabel: String {
        topModeLabel(for: topMode)
    }

    var utilityModeLabel: String {
        utilityModeLabel(for: utilityMode)
    }

    func topModeLabel(for mode: TopClockMode) -> String {
        switch mode {
        case .clock:
            return L10n.modeClock
        case .worldClock:
            return L10n.modeWorldClock
        case .calendar:
            return L10n.modeCalendar
        case .weather:
            return L10n.modeWeather
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

    func utilityModeLabel(for mode: UtilityMode) -> String {
        switch mode {
        case .audio:
            return L10n.modeAudio
        case .storage:
            return L10n.modeStorage
        case .network:
            return L10n.modeNetwork
        case .cpu:
            return L10n.modeCPU
        case .apps:
            return L10n.modeApps
        case .music:
            return L10n.modeMusic
        case .games:
            return L10n.modeGames
        case .info:
            return L10n.modeInfo
        }
    }

    var tunerInputLabel: String {
        if let selected = tunerEngine.inputs.first(where: { $0.id == tunerEngine.selectedInputID }) {
            return selected.name
        }
        return L10n.tunerSelectInput
    }

    var tunerSourceLabel: String {
        if let selected = tunerEngine.inputSources.first(where: { $0.id == tunerEngine.selectedInputSourceID }) {
            return selected.name
        }
        return L10n.tunerSelectSource
    }

    var tunerClampedCents: Double {
        max(-50, min(50, tunerEngine.cents))
    }

    func tunerBarWidth(total: CGFloat) -> CGFloat {
        let ratio = CGFloat((tunerClampedCents + 50) / 100)
        return max(6, total * ratio)
    }

    var tunerBarColor: Color {
        if abs(tunerEngine.cents) <= 5, tunerEngine.frequency > 0 {
            return Color.green
        }
        if tunerEngine.cents > 0, tunerEngine.frequency > 0 {
            return Color.red
        }
        return tunerBelowColor
    }

    var tunerStatusText: String {
        if tunerEngine.frequency <= 0 {
            return L10n.tunerNoSignal
        }
        return String(format: "%.1f Hz  %+0.1f¢", tunerEngine.frequency, tunerEngine.cents)
    }

    var chordDetectStatusText: String {
        if tunerEngine.detectedChordName == "--" {
            return L10n.tunerNoSignal
        }
        let confidence = Int((tunerEngine.detectedChordConfidence * 100).rounded())
        let notes = tunerEngine.detectedChordNotes.isEmpty ? "--" : tunerEngine.detectedChordNotes.joined(separator: " ")
        return "conf \(confidence)%  \(notes)"
    }

    var activeChordKeyText: String {
        parsedChord?.symbol ?? "--"
    }

    var chordVoicings: [ChordVoicing] {
        chordGeneratedVoicings
    }

    var activeChordVoicing: ChordVoicing? {
        guard chordVoicings.isEmpty == false else { return nil }
        let index = min(max(chordVoicingIndex, 0), chordVoicings.count - 1)
        return chordVoicings[index]
    }

    var chordVoicingPositionText: String {
        guard chordVoicings.isEmpty == false else { return "0/0" }
        let current = min(max(chordVoicingIndex, 0), chordVoicings.count - 1) + 1
        return "\(current)/\(chordVoicings.count)"
    }

    func rotateChordVoicingForward() {
        guard chordVoicings.isEmpty == false else { return }
        chordVoicingIndex = (chordVoicingIndex + 1) % chordVoicings.count
    }

    func rotateChordVoicingBackward() {
        guard chordVoicings.isEmpty == false else { return }
        chordVoicingIndex = (chordVoicingIndex - 1 + chordVoicings.count) % chordVoicings.count
    }

    func refreshChordFinder() {
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

    func parseChord(from raw: String) -> ParsedChord? {
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

    func preferredChordVoicings(for key: String) -> [ChordVoicing] {
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

    func pitchClassForRoot(_ root: String) -> Int? {
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

    func generateChordVoicings(for chord: ParsedChord) -> [ChordVoicing] {
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

    func chordVoicingIsDisplayable(_ voicing: ChordVoicing) -> Bool {
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

    func chordVoicingScore(_ voicing: ChordVoicing) -> Double {
        let fretted = voicing.frets.filter { $0 > 0 }
        let muted = voicing.frets.filter { $0 < 0 }.count
        let open = voicing.frets.filter { $0 == 0 }.count
        let maxFret = fretted.max() ?? 0
        let minFret = fretted.min() ?? 0
        let span = fretted.isEmpty ? 0 : (maxFret - minFret)
        return Double(maxFret) + (Double(span) * 1.8) + (Double(muted) * 0.7) - (Double(open) * 0.2)
    }

    func assignFingers(for frets: [Int]) -> [Int] {
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
    func chordDiagram(voicing: ChordVoicing) -> some View {
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


    var unifiedStorageAndUSBVolumes: [USBVolumeInfo] {
        let usb = usbMonitor.volumes.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        let storage = usbMonitor.storageVolumes.sorted { lhs, rhs in
            let lhsRank = unifiedStorageSortRank(lhs.label)
            let rhsRank = unifiedStorageSortRank(rhs.label)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
        }
        return usb + storage
    }

    func unifiedStorageSortRank(_ label: String) -> Int {
        let normalized = label.lowercased() == "machintosh hd" ? "macintosh hd" : label.lowercased()
        if normalized == "macintosh hd" { return 0 }
        if normalized == "externo" { return 1 }
        if normalized == "time machine" { return 2 }
        return 3
    }

    var storageInfoTotalText: String {
        isSpanishLanguage ? "total" : "total"
    }

    var storageInfoUsedText: String {
        isSpanishLanguage ? "usado" : "used"
    }

    var storageInfoFileSystemText: String {
        "FS"
    }

    @ViewBuilder
    func unifiedStorageAndUSBList(
        _ volumes: [USBVolumeInfo],
        rowFontSize: CGFloat,
        topInset: CGFloat
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(volumes) { volume in
                    HStack(alignment: .center, spacing: 12) {
                        DiskPieChart(
                            usedBytes: max(0, volume.totalBytes - volume.freeBytes),
                            freeBytes: max(0, volume.freeBytes)
                        )
                        .frame(width: rowFontSize * 1.05, height: rowFontSize * 1.05)

                        Button(action: {
                            storageInfoPopoverVolumeID = volume.id
                        }) {
                            Text(volume.label)
                                .font(displayFont(size: rowFontSize * 0.72, weight: .semibold))
                                .foregroundStyle(phosphorColor)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .shadow(color: phosphorColor.opacity(0.5), radius: 3)
                        }
                        .buttonStyle(.plain)
                        .popover(
                            isPresented: Binding(
                                get: { storageInfoPopoverVolumeID == volume.id },
                                set: { isPresented in
                                    if isPresented == false {
                                        storageInfoPopoverVolumeID = nil
                                    }
                                }
                            ),
                            arrowEdge: .top
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(storageInfoTotalText): \(volume.totalCompactText)")
                                    .font(displayFont(size: 20, weight: .regular))
                                    .foregroundStyle(phosphorDim)
                                Text("\(storageInfoUsedText): \(USBVolumeMonitor.compactByteString(max(0, volume.totalBytes - volume.freeBytes)))")
                                    .font(displayFont(size: 20, weight: .regular))
                                    .foregroundStyle(phosphorDim)
                                Text("\(storageInfoFileSystemText): \(volume.fileSystem)")
                                    .font(displayFont(size: 20, weight: .regular))
                                    .foregroundStyle(phosphorDim)
                            }
                            .padding(18)
                            .frame(minWidth: 520, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.black.opacity(0.92))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.42), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: 920, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .offset(x: 72)
            .padding(.horizontal, 12)
            .padding(.top, topInset)
            .padding(.bottom, 12)
        }
    }




    #if os(macOS)
    func triggerFlash(reason: FlashReason = .general) {
        if utilityMode == .games, selectedGameMode == .spaceInvaders, reason != .spaceInvadersPlayerHit {
            return
        }
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

struct PressableCountdownButtonStyle: ButtonStyle {
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
struct MouseClickCatcher: NSViewRepresentable {
    let onLeftClick: () -> Void
    let onRightClick: () -> Void
    var onScroll: ((CGFloat) -> Void)? = nil

    func makeNSView(context: Context) -> RepeatClickNSView {
        let view = RepeatClickNSView()
        view.onLeftClick = onLeftClick
        view.onRightClick = onRightClick
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: RepeatClickNSView, context: Context) {
        nsView.onLeftClick = onLeftClick
        nsView.onRightClick = onRightClick
        nsView.onScroll = onScroll
    }
}

final class RepeatClickNSView: NSView {
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?
    var onScroll: ((CGFloat) -> Void)?

    enum ActiveButton {
        case left
        case right
    }

    let holdDelay: TimeInterval = 0.28
    let repeatInterval: TimeInterval = 0.055
    var activeButton: ActiveButton?
    var holdScheduledButton: ActiveButton?
    var repeatTimer: Timer?

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

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.scrollingDeltaY)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            stopRepeat()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    func beginPress(_ button: ActiveButton) {
        activeButton = button
        holdScheduledButton = button
        fire(button)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginRepeatIfStillPressed), object: nil)
        perform(#selector(beginRepeatIfStillPressed), with: nil, afterDelay: holdDelay)
    }

    func endPress(_ button: ActiveButton) {
        guard activeButton == button else { return }
        stopRepeat()
    }

    func startRepeat(_ button: ActiveButton) {
        guard activeButton == button else { return }
        repeatTimer?.invalidate()
        repeatTimer = Timer(timeInterval: repeatInterval, target: self, selector: #selector(repeatTick), userInfo: nil, repeats: true)
        if let repeatTimer {
            RunLoop.main.add(repeatTimer, forMode: .common)
        }
    }

    @objc
    func beginRepeatIfStillPressed() {
        guard let button = holdScheduledButton, activeButton == button else { return }
        startRepeat(button)
    }

    @objc
    func repeatTick() {
        guard let button = activeButton else {
            stopRepeat()
            return
        }
        fire(button)
    }

    func stopRepeat() {
        activeButton = nil
        holdScheduledButton = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(beginRepeatIfStillPressed), object: nil)
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    func fire(_ button: ActiveButton) {
        switch button {
        case .left:
            onLeftClick?()
        case .right:
            onRightClick?()
        }
    }
}

struct MouseScrollCatcher: NSViewRepresentable {
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

final class ScrollCaptureNSView: NSView {
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

struct MouseTrackingCatcher: NSViewRepresentable {
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

final class MouseTrackingNSView: NSView {
    var onMove: ((CGPoint) -> Void)?
    var onLeftClick: ((CGPoint) -> Void)?
    var onRightClick: ((CGPoint) -> Void)?
    var trackingAreaRef: NSTrackingArea?

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

struct DiskPieChart: View {
    let usedBytes: Int64
    let freeBytes: Int64

    var total: Double {
        max(0, Double(usedBytes + freeBytes))
    }

    var usedFraction: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, Double(usedBytes) / total))
    }

    var freeFraction: Double {
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

struct CRTScanlines: View {
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

struct PieSliceShape: Shape {
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
struct WindowReader: NSViewRepresentable {
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
