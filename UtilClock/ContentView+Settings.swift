import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

extension ContentView {
    var settingsView: some View {
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
/*
                        Text("Presentacion app / App presentation")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        HStack(spacing: 10) {
                            Button(action: { setMenuBarOnlyMode(false) }) {
                                Text("Dock")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(menuBarOnlyMode ? 0.35 : 0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(menuBarOnlyMode ? 0.4 : 0.9), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: { setMenuBarOnlyMode(true) }) {
                                Text("Barra de menús")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(menuBarOnlyMode ? 0.65 : 0.35))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(menuBarOnlyMode ? 0.9 : 0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        Text("Inicio de sesion / Login")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        HStack(spacing: 10) {
                            Button(action: { setLaunchAtLoginEnabled(true) }) {
                                Text("Auto-inicio ON")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(launchAtLoginEnabled ? 0.65 : 0.35))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(launchAtLoginEnabled ? 0.9 : 0.4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: { setLaunchAtLoginEnabled(false) }) {
                                Text("Auto-inicio OFF")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(launchAtLoginEnabled ? 0.35 : 0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(launchAtLoginEnabled ? 0.4 : 0.9), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if let launchAtLoginErrorText, launchAtLoginErrorText.isEmpty == false {
                            Text(launchAtLoginErrorText)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.66))
                        }

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)
*/
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
                            ForEach(utilityModeOrder, id: \.self) { mode in
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

                                    if mode == .games {
                                        Text("pong \(pongFieldSizeLevel)")
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

                                        Text("snake \(snakeBoardSizeLevel)")
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

                                        Text("arkanoid barra \(arkanoidPaddleSizeLevel)")
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
                                                    onLeftClick: { rotateArkanoidPaddleSize(forward: true) },
                                                    onRightClick: { rotateArkanoidPaddleSize(forward: false) }
                                                )
                                            )
                                            #else
                                            .onTapGesture {
                                                rotateArkanoidPaddleSize(forward: true)
                                            }
                                            #endif

                                        Text(artilleryWindEnabled ? "wind on" : "wind off")
                                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(artilleryWindEnabled ? phosphorColor : phosphorDim)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.35))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                    .stroke(
                                                        (artilleryWindEnabled ? phosphorColor : phosphorDim).opacity(0.45),
                                                        lineWidth: 1
                                                    )
                                            )
                                            #if os(macOS)
                                            .overlay(
                                                MouseClickCatcher(
                                                    onLeftClick: { toggleArtilleryWind() },
                                                    onRightClick: { toggleArtilleryWind() }
                                                )
                                            )
                                            #else
                                            .onTapGesture {
                                                toggleArtilleryWind()
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

                        Divider()
                            .background(phosphorDim.opacity(0.4))
                            .padding(.vertical, 6)

                        HStack {
                            Text("Records / Highscores")
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                .foregroundStyle(phosphorDim)
                            Spacer()
                            Button(action: resetAllGameHighscores) {
                                Text("Poner todos a 0")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.red.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.red.opacity(0.55), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 7) {
                            ForEach(GameMode.allCases, id: \.self) { mode in
                                HStack(spacing: 8) {
                                    Text(gameTitle(for: mode).uppercased())
                                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    Text("\(highscore(for: mode))")
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                )
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

    func topModeToggleBinding(for mode: TopClockMode) -> Binding<Bool> {
        Binding(
            get: { enabledTopModes.contains(mode) },
            set: { setTopMode(mode, enabled: $0) }
        )
    }

    func utilityModeToggleBinding(for mode: UtilityMode) -> Binding<Bool> {
        Binding(
            get: { enabledUtilityModes.contains(mode) },
            set: { setUtilityMode(mode, enabled: $0) }
        )
    }

    func setTopMode(_ mode: TopClockMode, enabled: Bool) {
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

    func setUtilityMode(_ mode: UtilityMode, enabled: Bool) {
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

    func orderedEnabledTopModes() -> [TopClockMode] {
        let modes = topModeOrder.filter { enabledTopModes.contains($0) }
        return modes.isEmpty ? TopClockMode.allCases : modes
    }

    var availableUtilityModes: [UtilityMode] {
        UtilityMode.allCases
    }

    func orderedEnabledUtilityModes() -> [UtilityMode] {
        let modes = utilityModeOrder.filter { enabledUtilityModes.contains($0) }
        return modes.isEmpty ? availableUtilityModes : modes
    }

    func moveTopMode(_ mode: TopClockMode, up: Bool) {
        guard let index = topModeOrder.firstIndex(of: mode) else { return }
        let target = up ? index - 1 : index + 1
        guard topModeOrder.indices.contains(target) else { return }
        topModeOrder.swapAt(index, target)
        saveModeVisibilitySettings()
    }

    func moveUtilityMode(_ mode: UtilityMode, up: Bool) {
        guard let index = utilityModeOrder.firstIndex(of: mode) else { return }
        let target = up ? index - 1 : index + 1
        guard utilityModeOrder.indices.contains(target) else { return }
        utilityModeOrder.swapAt(index, target)
        saveModeVisibilitySettings()
    }

    func moveTopModes(from source: IndexSet, to destination: Int) {
        topModeOrder.move(fromOffsets: source, toOffset: destination)
        saveModeVisibilitySettings()
    }

    func moveUtilityModes(from source: IndexSet, to destination: Int) {
        utilityModeOrder.move(fromOffsets: source, toOffset: destination)
        saveModeVisibilitySettings()
    }

    func rotateTopMode(forward: Bool) {
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

    func rotateUtilityMode(forward: Bool) {
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

    func handleUtilityModeActivation(_ mode: UtilityMode) {
        if mode == .audio {
            refreshAudioDeviceName()
            refreshSystemAudioState(triggerOnMuteTransition: false)
        } else if mode == .network {
            refreshNetworkModeData(forcePublicIPRefresh: true)
        } else if mode == .cpu {
            refreshCPUUsage()
        } else if mode == .apps {
            refreshAppsMonitorData()
        } else if mode == .photos {
            refreshPhotosModeIfNeeded()
        } else if mode == .videos {
            refreshVideosModeIfNeeded()
        } else if mode == .music {
            syncMusicActivation()
        } else if mode == .info {
            syncInfoActivation()
        }
    }

    func loadModeVisibilitySettings() {
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
            let normalizedStoredUtility = Set(storedUtility.map { key in
                switch key {
                case "usb":
                    return "storage"
                case "pong", "arkanoid", "missileCommand", "snake", "chromeDino", "tetris", "spaceInvaders", "asteroids", "tron", "pacman", "frogger", "artillery":
                    return "games"
                case "metronome", "tuner", "chordDetect", "chordFinder":
                    return "music"
                case "volume":
                    return "audio"
                case "todayInHistory", "musicThought", "rae":
                    return "info"
                case "processes":
                    return "apps"
                default:
                    return key
                }
            })
            let restored = Set(availableUtilityModes.filter { normalizedStoredUtility.contains($0.key) })
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
            var seenUtilityKeys = Set<String>()
            let restoredOrder: [UtilityMode] = storedUtilityOrder.compactMap { (key: String) -> UtilityMode? in
                let normalizedKey: String
                switch key {
                case "usb":
                    normalizedKey = "storage"
                case "pong", "arkanoid", "missileCommand", "snake", "chromeDino", "tetris", "spaceInvaders", "asteroids", "tron", "pacman", "frogger", "artillery":
                    normalizedKey = "games"
                case "metronome", "tuner", "chordDetect", "chordFinder":
                    normalizedKey = "music"
                case "volume":
                    normalizedKey = "audio"
                case "todayInHistory", "musicThought", "rae":
                    normalizedKey = "info"
                case "processes":
                    normalizedKey = "apps"
                default:
                    normalizedKey = key
                }
                guard seenUtilityKeys.insert(normalizedKey).inserted else { return nil }
                return availableUtilityModes.first(where: { $0.key == normalizedKey })
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

        if defaults.object(forKey: menuBarOnlyModeKey) != nil {
            menuBarOnlyMode = defaults.bool(forKey: menuBarOnlyModeKey)
        } else {
            menuBarOnlyMode = false
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

        let savedArkanoidPaddleSize = defaults.integer(forKey: "utilclock.arkanoidPaddleSizeLevel")
        if savedArkanoidPaddleSize >= 1, savedArkanoidPaddleSize <= 9 {
            arkanoidPaddleSizeLevel = savedArkanoidPaddleSize
        } else {
            arkanoidPaddleSizeLevel = 5
        }

        if let storedHighscores = defaults.dictionary(forKey: "utilclock.gameHighscores") {
            var normalized: [String: Int] = [:]
            for mode in GameMode.allCases {
                let rawValue = storedHighscores[mode.rawValue]
                let score: Int
                if let value = rawValue as? Int {
                    score = value
                } else if let number = rawValue as? NSNumber {
                    score = number.intValue
                } else {
                    score = 0
                }
                normalized[mode.rawValue] = max(0, score)
            }
            gameHighscoresByKey = normalized
        } else {
            gameHighscoresByKey = Dictionary(uniqueKeysWithValues: GameMode.allCases.map { ($0.rawValue, 0) })
        }

        if defaults.object(forKey: "utilclock.artilleryWindEnabled") != nil {
            artilleryWindEnabled = defaults.bool(forKey: "utilclock.artilleryWindEnabled")
        } else {
            artilleryWindEnabled = false
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

    func saveModeVisibilitySettings() {
        let defaults = UserDefaults.standard
        defaults.set(displayPalette.rawValue, forKey: "utilclock.displayPalette")
        defaults.set(orderedEnabledTopModes().map(\.key), forKey: "utilclock.enabledTopModes")
        defaults.set(orderedEnabledUtilityModes().map(\.key), forKey: "utilclock.enabledUtilityModes")
        defaults.set(topModeOrder.map(\.key), forKey: "utilclock.topModeOrder")
        defaults.set(utilityModeOrder.map(\.key), forKey: "utilclock.utilityModeOrder")
        defaults.set(max(1, min(4, pongFieldSizeLevel)), forKey: "utilclock.pongFieldSizeLevel")
        defaults.set(max(1, min(4, snakeBoardSizeLevel)), forKey: "utilclock.snakeBoardSizeLevel")
        defaults.set(max(1, min(9, arkanoidPaddleSizeLevel)), forKey: "utilclock.arkanoidPaddleSizeLevel")
        defaults.set(artilleryWindEnabled, forKey: "utilclock.artilleryWindEnabled")
        defaults.set(gameHighscoresByKey, forKey: "utilclock.gameHighscores")
        defaults.set(preferredFullscreen, forKey: preferredFullscreenKey)
        defaults.set(menuBarOnlyMode, forKey: menuBarOnlyModeKey)
    }

    func rotatePongFieldSize(forward: Bool) {
        let current = max(1, min(4, pongFieldSizeLevel))
        if forward {
            pongFieldSizeLevel = current == 4 ? 1 : current + 1
        } else {
            pongFieldSizeLevel = current == 1 ? 4 : current - 1
        }
        saveModeVisibilitySettings()
    }

    func rotateSnakeBoardSize(forward: Bool) {
        let current = max(1, min(4, snakeBoardSizeLevel))
        if forward {
            snakeBoardSizeLevel = current == 4 ? 1 : current + 1
        } else {
            snakeBoardSizeLevel = current == 1 ? 4 : current - 1
        }
        resetSnakeGame()
        saveModeVisibilitySettings()
    }

    func rotateArkanoidPaddleSize(forward: Bool) {
        let current = max(1, min(9, arkanoidPaddleSizeLevel))
        if forward {
            arkanoidPaddleSizeLevel = current == 9 ? 1 : current + 1
        } else {
            arkanoidPaddleSizeLevel = current == 1 ? 9 : current - 1
        }
        saveModeVisibilitySettings()
    }

    func resetAllGameHighscores() {
        gameHighscoresByKey = Dictionary(uniqueKeysWithValues: GameMode.allCases.map { ($0.rawValue, 0) })
        gameNewHighscoreMode = nil
        gameNewHighscoreValue = 0
        saveModeVisibilitySettings()
    }

    func toggleArtilleryWind() {
        artilleryWindEnabled.toggle()
        saveModeVisibilitySettings()
        if utilityMode == .games, selectedGameMode == .artillery {
            randomizeArtilleryWind()
        }
    }

    func toggleSplitFullscreen(_ target: SplitFullscreenTarget) {
        if splitFullscreenTarget == target {
            splitFullscreenTarget = .none
        } else {
            splitFullscreenTarget = target
        }
    }

    func splitFullscreenIcon(for target: SplitFullscreenTarget) -> String {
        splitFullscreenTarget == target
            ? "arrow.down.right.and.arrow.up.left"
            : "arrow.up.left.and.arrow.down.right"
    }

    func splitFullscreenButton(target: SplitFullscreenTarget) -> some View {
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

    func modeSelectorTag(
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

    func appsMonitorToggleButton(title: String, mode: AppsMonitorMode) -> some View {
        Button(action: {
            selectedAppsMonitorMode = mode
            refreshAppsMonitorData()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode == selectedAppsMonitorMode ? phosphorColor : phosphorDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(mode == selectedAppsMonitorMode ? 0.55 : 0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(phosphorColor.opacity(mode == selectedAppsMonitorMode ? 0.55 : 0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    #if os(macOS)
    var startupScreenPickerView: some View {
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
}

