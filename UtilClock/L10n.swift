//
//  L10n.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import Foundation

enum L10n {
    private static var isSpanish: Bool {
        guard let language = Locale.preferredLanguages.first?.lowercased() else {
            return false
        }
        return language.hasPrefix("es")
    }

    private static func text(es: String, en: String) -> String {
        isSpanish ? es : en
    }

    static var externalDrives: String {
        text(es: "Unidades externas", en: "External drives")
    }

    static var toggleFullScreen: String {
        text(es: "Alternar pantalla completa", en: "Toggle Full Screen")
    }

    static var enableAlwaysOnTop: String {
        text(es: "Activar siempre visible", en: "Enable Always on Top")
    }

    static var disableAlwaysOnTop: String {
        text(es: "Desactivar siempre visible", en: "Disable Always on Top")
    }

    static var unknownFileSystem: String {
        text(es: "Desconocido", en: "Unknown")
    }

    static var modeClock: String {
        text(es: "reloj", en: "clock")
    }

    static var modeWorldClock: String {
        text(es: "reloj mundial", en: "world clock")
    }

    static var modeCalendar: String {
        text(es: "calendario", en: "calendar")
    }

    static var modeWeather: String {
        text(es: "tiempo", en: "weather")
    }

    static var modeAwake: String {
        text(es: "despierto", en: "awake")
    }

    static var modeStopwatch: String {
        text(es: "cronometro", en: "stopwatch")
    }

    static var stopwatchPrecountdownShort: String {
        text(es: "pre", en: "pre")
    }

    static var modeCountdown: String {
        text(es: "cuenta atras", en: "countdown")
    }

    static var modeAlarm: String {
        text(es: "alarma", en: "alarm")
    }

    static var modeFullClock: String {
        text(es: "reloj total", en: "full clock")
    }

    static var modeAudio: String {
        text(es: "audio", en: "audio")
    }

    static var modeUSB: String {
        text(es: "usb", en: "usb")
    }

    static var modeStorage: String {
        text(es: "almacenamiento", en: "storage")
    }

    static var modeNetwork: String {
        text(es: "red", en: "network")
    }

    static var modeCPU: String {
        text(es: "cpu", en: "cpu")
    }

    static var modeApps: String {
        text(es: "apps", en: "apps")
    }

    static var modePhotos: String {
        text(es: "ver fotos", en: "view photos")
    }

    static var modeVideos: String {
        text(es: "ver videos", en: "view videos")
    }

    static var videosAlbumButton: String {
        text(es: "album fotos", en: "photos album")
    }

    static var videosFolderButton: String {
        text(es: "carpeta", en: "folder")
    }

    static var videosSource: String {
        text(es: "origen", en: "source")
    }

    static var videosNoAlbums: String {
        text(es: "sin albumes con video", en: "no albums with videos")
    }

    static var videosCount: String {
        text(es: "videos", en: "videos")
    }

    static var videosLoading: String {
        text(es: "cargando...", en: "loading...")
    }

    static var videosShuffle: String {
        text(es: "aleatorio", en: "shuffle")
    }

    static var videosSound: String {
        text(es: "sonido", en: "sound")
    }

    static var photosAlbumButton: String {
        text(es: "album fotos", en: "photos album")
    }

    static var photosFolderButton: String {
        text(es: "carpeta", en: "folder")
    }

    static var photosShowClock: String {
        text(es: "mostrar reloj", en: "show clock")
    }

    static var photosDuration: String {
        text(es: "duracion", en: "duration")
    }

    static var photosRequestPermission: String {
        text(es: "pedir permiso", en: "request permission")
    }

    static var photosNoAlbums: String {
        text(es: "sin albumes", en: "no albums")
    }

    static var photosSource: String {
        text(es: "origen", en: "source")
    }

    static var photosCount: String {
        text(es: "fotos", en: "photos")
    }

    static var photosLoading: String {
        text(es: "cargando...", en: "loading...")
    }

    static var photosPermissionDenied: String {
        text(es: "permiso no concedido: denied", en: "permission not granted: denied")
    }

    static var photosPermissionRestricted: String {
        text(es: "permiso restringido", en: "permission restricted")
    }

    static var photosPermissionLimited: String {
        text(es: "permiso limitado", en: "permission limited")
    }

    static var photosPermissionNotDetermined: String {
        text(es: "falta permiso para leer albumes de fotos", en: "photos access permission required")
    }

    static var photosPermissionUnknown: String {
        text(es: "permiso de fotos desconocido", en: "unknown photos permission")
    }

    static var select: String {
        text(es: "Seleccionar", en: "Select")
    }

    static var modeProcesses: String {
        text(es: "procesos", en: "processes")
    }

    static var modeMusic: String {
        text(es: "musica", en: "music")
    }

    static var modeVolume: String {
        text(es: "volumen", en: "volume")
    }

    static var modeMetronome: String {
        text(es: "metronomo", en: "metronome")
    }

    static var modeTapTempo: String {
        text(es: "tap tempo", en: "tap tempo")
    }

    static var tapTempoTap: String {
        text(es: "tap", en: "tap")
    }

    static var tapTempoTapSingular: String {
        text(es: "tap", en: "tap")
    }

    static var tapTempoTapPlural: String {
        text(es: "taps", en: "taps")
    }

    static var modeTuner: String {
        text(es: "afinador", en: "tuner")
    }

    static var modeChordDetect: String {
        text(es: "detector de acordes", en: "chord detect")
    }

    static var modeChordFinder: String {
        text(es: "buscador de acordes", en: "chord finder")
    }

    static var modeGames: String {
        text(es: "juegos", en: "games")
    }

    static var modeInfo: String {
        text(es: "info", en: "info")
    }

    static var modeTeleprompter: String {
        text(es: "teleprompter", en: "teleprompter")
    }

    static var teleprompterLoadFile: String {
        text(es: "cargar archivo", en: "load file")
    }

    static var teleprompterNoFile: String {
        text(es: "sin archivo cargado", en: "no file loaded")
    }

    static var teleprompterPlay: String {
        text(es: "play", en: "play")
    }

    static var teleprompterPause: String {
        text(es: "pausa", en: "pause")
    }

    static var teleprompterSpeed: String {
        text(es: "velocidad", en: "speed")
    }

    static var teleprompterFullscreen: String {
        text(es: "pantalla completa", en: "fullscreen")
    }

    static var teleprompterExitFullscreen: String {
        text(es: "salir pantalla completa", en: "exit fullscreen")
    }

    static var modePong: String {
        text(es: "pong", en: "pong")
    }

    static var modeArkanoid: String {
        text(es: "arkanoid", en: "arkanoid")
    }

    static var modeMissileCommand: String {
        text(es: "missile command", en: "missile command")
    }

    static var modeSnake: String {
        text(es: "serpiente", en: "snake")
    }

    static var modeChromeDino: String {
        text(es: "jump n' run", en: "jump n' run")
    }

    static var modeTetris: String {
        text(es: "tetris", en: "tetris")
    }

    static var modeSpaceInvaders: String {
        text(es: "space invaders", en: "space invaders")
    }

    static var modeAsteroids: String {
        text(es: "asteroids", en: "asteroids")
    }

    static var modeTron: String {
        text(es: "tron", en: "tron")
    }

    static var modePacman: String {
        text(es: "pac-man", en: "pac-man")
    }

    static var modeFrogger: String {
        text(es: "frogger", en: "frogger")
    }

    static var modeArtillery: String {
        text(es: "artilleria", en: "artillery")
    }

    static var modeBackRooms: String {
        text(es: "back rooms", en: "back rooms")
    }

    static var modeDoom: String {
        text(es: "doom", en: "doom")
    }

    static var modeTodayInHistory: String {
        text(es: "tal dia", en: "this day")
    }

    static var modeMusicThought: String {
        text(es: "frase musical", en: "music thought")
    }

    static var modeRAE: String {
        text(es: "rae", en: "rae")
    }

    static var start: String {
        text(es: "start", en: "start")
    }

    static var stop: String {
        text(es: "stop", en: "stop")
    }

    static var reset: String {
        text(es: "reset", en: "reset")
    }

    static var hoursShort: String {
        text(es: "h", en: "h")
    }

    static var minutesShort: String {
        text(es: "m", en: "m")
    }

    static var secondsShort: String {
        text(es: "s", en: "s")
    }

    static var selectedAudio: String {
        text(es: "dispositivo seleccionado", en: "selected device")
    }

    static var noAudioDevice: String {
        text(es: "sin dispositivo", en: "no device")
    }

    static var cpuUsage: String {
        text(es: "uso cpu", en: "cpu usage")
    }

    static var runningAppsCPU: String {
        text(es: "apps en ejecucion (cpu)", en: "running apps (cpu)")
    }

    static var noRunningAppsCPUData: String {
        text(es: "sin apps para mostrar", en: "no apps to display")
    }

    static var noRunningProcessesCPUData: String {
        text(es: "sin procesos para mostrar", en: "no processes to display")
    }

    static var networkPublicIP: String {
        text(es: "IP publica", en: "Public IP")
    }

    static var networkPrivateIP: String {
        text(es: "IP privada", en: "Private IP")
    }

    static var networkDownload: String {
        text(es: "bajada", en: "download")
    }

    static var networkUpload: String {
        text(es: "subida", en: "upload")
    }

    static var networkWiFi: String {
        text(es: "Wi-Fi", en: "Wi-Fi")
    }

    static var networkEthernet: String {
        text(es: "Ethernet", en: "Ethernet")
    }

    static var networkNoData: String {
        text(es: "sin datos", en: "no data")
    }

    static var quitApp: String {
        text(es: "cerrar aplicacion", en: "quit app")
    }

    static var quitAppTitle: String {
        text(es: "cerrar aplicacion", en: "quit app")
    }

    static var quitAppConfirmationMessage: String {
        text(es: "se cerrara UtilClock. ¿quieres continuar?", en: "UtilClock will close. Do you want to continue?")
    }

    static var cancel: String {
        text(es: "cancelar", en: "cancel")
    }

    static var quit: String {
        text(es: "salir", en: "quit")
    }

    static var menuChangeMonitor: String {
        text(es: "cambiar monitor", en: "change monitor")
    }

    static var menuEnableFullscreen: String {
        text(es: "activar pantalla completa", en: "enable fullscreen")
    }

    static var menuDisableFullscreen: String {
        text(es: "desactivar pantalla completa", en: "disable fullscreen")
    }

    static var menuQuit: String {
        text(es: "Salir", en: "Quit")
    }

    static var systemVolume: String {
        text(es: "volumen del sistema", en: "system volume")
    }

    static var tunerSelectInput: String {
        text(es: "selecciona entrada", en: "select input")
    }

    static var tunerSelectSource: String {
        text(es: "selecciona fuente", en: "select source")
    }

    static var tunerNoSources: String {
        text(es: "sin fuentes", en: "no sources")
    }

    static var tunerNoSignal: String {
        text(es: "sin senal", en: "no signal")
    }

    static var tunerMicPermission: String {
        text(es: "activa permiso de microfono", en: "enable microphone permission")
    }

    static var tunerRequestPermission: String {
        text(es: "pedir permiso", en: "request permission")
    }

    static var chordFinderPlaceholder: String {
        text(es: "acorde (ej: Am, Cmaj7)", en: "chord (e.g. Am, Cmaj7)")
    }

    static var chordFinderNoMatch: String {
        text(es: "sin posiciones", en: "no voicings")
    }

    static var chordFinderTapHint: String {
        text(es: "click en diagrama para rotar", en: "click diagram to rotate")
    }

    static var raePlaceholder: String {
        text(es: "palabra (ej: casa)", en: "word (e.g. house)")
    }

    static var raeSearch: String {
        text(es: "buscar en rae", en: "search in rae")
    }

    static var raeOpenInBrowser: String {
        text(es: "abrir en navegador", en: "open in browser")
    }

    static var raeHint: String {
        text(es: "escribe una palabra y pulsa buscar", en: "type a word and press search")
    }

    static var raeInvalidWord: String {
        text(es: "palabra no valida", en: "invalid word")
    }

    static var raeLastSearch: String {
        text(es: "ultima busqueda", en: "last search")
    }

    static var weatherLoading: String {
        text(es: "cargando tiempo...", en: "loading weather...")
    }

    static var weatherError: String {
        text(es: "error obteniendo tiempo", en: "weather fetch error")
    }

}
