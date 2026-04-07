import SwiftUI
import Combine
#if os(macOS)
import AppKit
import MapKit
import UniformTypeIdentifiers
#endif

#if os(macOS)
struct WeatherLocationSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion
}

@MainActor
final class WeatherLocationSearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = ""
    @Published var suggestions: [WeatherLocationSuggestion] = []
    @Published var isResolvingSelection = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ newValue: String) {
        query = newValue
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        completer.queryFragment = trimmed
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(8).map {
            WeatherLocationSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }

    func clear() {
        query = ""
        suggestions = []
        isResolvingSelection = false
        completer.queryFragment = ""
    }

    func resolve(_ suggestion: WeatherLocationSuggestion, completion: @escaping (Result<WeatherResolvedLocation, Error>) -> Void) {
        isResolvingSelection = true
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self else { return }
            self.isResolvingSelection = false

            if let item = response?.mapItems.first {
                let coordinate = item.location.coordinate
                let parts = [suggestion.title, suggestion.subtitle]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
                completion(.success(WeatherResolvedLocation(latitude: coordinate.latitude, longitude: coordinate.longitude, locationName: parts.joined(separator: ", "))))
                return
            }

            completion(.failure(error ?? NSError(domain: "WeatherLocationSearch", code: 1, userInfo: [NSLocalizedDescriptionKey: "no se pudo resolver la ubicacion"])))
        }
    }
}
#else
@MainActor
final class WeatherLocationSearchModel: ObservableObject {
    @Published var query = ""
    @Published var suggestions: [String] = []
    @Published var isResolvingSelection = false

    func updateQuery(_ newValue: String) {
        query = newValue
    }

    func clear() {
        query = ""
        suggestions = []
        isResolvingSelection = false
    }
}
#endif

extension ContentView {
    var allTopScreenModes: [ScreenModeItem] {
        topScreenModeOrder
    }

    var allBottomScreenModes: [ScreenModeItem] {
        bottomScreenModeOrder
    }

    func screenModeLabel(for item: ScreenModeItem) -> String {
        switch item {
        case .top(let mode):
            return topModeLabel(for: mode)
        case .utility(let mode):
            return utilityModeLabel(for: mode)
        }
    }

    func isScreenModeEnabled(_ item: ScreenModeItem) -> Bool {
        switch item {
        case .top(let mode):
            return enabledTopModes.contains(mode)
        case .utility(let mode):
            return enabledUtilityModes.contains(mode)
        }
    }

    func setScreenMode(_ item: ScreenModeItem, enabled: Bool) {
        switch item {
        case .top(let mode):
            setTopMode(mode, enabled: enabled)
        case .utility(let mode):
            setUtilityMode(mode, enabled: enabled)
        }

        if enabled == false {
            if topScreenSelectedMode == item, let fallback = firstEnabledMode(in: topScreenModeOrder) {
                activateScreenMode(fallback, on: .top)
            }
            if bottomScreenSelectedMode == item, let fallback = firstEnabledMode(in: bottomScreenModeOrder) {
                activateScreenMode(fallback, on: .bottom)
            }
        }
        saveModeVisibilitySettings()
    }

    func enabledModes(in items: [ScreenModeItem]) -> [ScreenModeItem] {
        let modes = items.filter { isScreenModeEnabled($0) }
        return modes.isEmpty ? items : modes
    }

    func screenModeItem(forKey key: String) -> ScreenModeItem? {
        let raw = key.split(separator: ":", maxSplits: 1).map(String.init)
        if raw.count == 2 {
            if raw[0] == "top", let mode = TopClockMode.allCases.first(where: { $0.key == raw[1] }) {
                return .top(mode)
            }
            if raw[0] == "utility", let mode = UtilityMode.allCases.first(where: { $0.key == raw[1] }) {
                return .utility(mode)
            }
        }

        if let mode = TopClockMode.allCases.first(where: { $0.key == key }) {
            return .top(mode)
        }
        if let mode = UtilityMode.allCases.first(where: { $0.key == key }) {
            return .utility(mode)
        }
        return nil
    }

    func firstEnabledMode(in items: [ScreenModeItem], topFamily: Bool? = nil) -> ScreenModeItem? {
        enabledModes(in: items).first { item in
            guard let topFamily else { return true }
            return item.isTopFamily == topFamily
        }
    }

    func activateScreenMode(_ item: ScreenModeItem, on screen: ScreenSlot) {
        switch item {
        case .top(let mode):
            if screen == .top {
                topScreenTopMode = mode
            } else {
                bottomScreenTopMode = mode
            }
        case .utility(let mode):
            if screen == .top {
                topScreenUtilityMode = mode
            } else {
                bottomScreenUtilityMode = mode
            }
            handleUtilityModeActivation(mode)
        }

        if screen == .top {
            topScreenSelectedMode = item
        } else {
            bottomScreenSelectedMode = item
        }
    }

    func moveScreenMode(_ item: ScreenModeItem, to screen: ScreenSlot) {
        let sourceItems = screen == .top ? bottomScreenModeOrder : topScreenModeOrder
        guard sourceItems.count > 1 else { return }

        if screen == .top {
            bottomScreenModeOrder.removeAll { $0 == item }
            if topScreenModeOrder.contains(item) == false {
                topScreenModeOrder.append(item)
            }
        } else {
            topScreenModeOrder.removeAll { $0 == item }
            if bottomScreenModeOrder.contains(item) == false {
                bottomScreenModeOrder.append(item)
            }
        }

        let otherScreen: ScreenSlot = screen == .top ? .bottom : .top
        let otherItems = otherScreen == .top ? topScreenModeOrder : bottomScreenModeOrder
        let otherSelected = otherScreen == .top ? topScreenSelectedMode : bottomScreenSelectedMode
        if otherItems.contains(otherSelected) == false,
           let fallback = firstEnabledMode(in: otherItems) {
            if screen == .top {
                activateScreenMode(fallback, on: .bottom)
            } else {
                activateScreenMode(fallback, on: .top)
            }
        }

        saveModeVisibilitySettings()
    }

    func rotateScreenMode(on screen: ScreenSlot, forward: Bool) {
        let modes = enabledModes(in: screen == .top ? topScreenModeOrder : bottomScreenModeOrder)
        guard modes.isEmpty == false else { return }
        let current = screen == .top ? topScreenSelectedMode : bottomScreenSelectedMode
        guard let currentIndex = modes.firstIndex(of: current) else {
            activateScreenMode(modes[0], on: screen)
            return
        }
        let nextIndex = forward
            ? (currentIndex + 1) % modes.count
            : (currentIndex - 1 + modes.count) % modes.count
        activateScreenMode(modes[nextIndex], on: screen)
    }

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

                        Text("Tiempo / Weather")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        Text(weatherManualLocationSummary)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Buscar ciudad o lugar", text: Binding(
                                get: { weatherLocationSearch.query },
                                set: { weatherLocationSearch.updateQuery($0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .frame(maxWidth: 320)

                            if weatherLocationSearch.isResolvingSelection {
                                Text("resolviendo ubicacion...")
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                            } else if weatherLocationSearch.suggestions.isEmpty == false {
                                VStack(spacing: 7) {
                                    ForEach(weatherLocationSearch.suggestions) { suggestion in
                                        Button(action: {
                                            applyManualWeatherLocationSuggestion(suggestion)
                                        }) {
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: "mappin.and.ellipse")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(phosphorColor)
                                                    .frame(width: 18, alignment: .center)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(suggestion.title)
                                                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                                        .foregroundStyle(phosphorColor)
                                                        .frame(maxWidth: .infinity, alignment: .leading)

                                                    if suggestion.subtitle.isEmpty == false {
                                                        Text(suggestion.subtitle)
                                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                            .foregroundStyle(phosphorDim)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(Color.black.opacity(0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: 420, alignment: .leading)
                            }

                            Button(action: clearManualWeatherLocation) {
                                Text("Limpiar ubicacion")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.35))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(phosphorColor.opacity(0.4), lineWidth: 1)
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
                            ForEach(allTopScreenModes, id: \.self) { item in
                                HStack(spacing: 10) {
                                    Text("≡")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .onDrag {
                                            draggedScreenMode = item
                                            return NSItemProvider(object: NSString(string: item.key))
                                        }
                                    Button(action: {
                                        setScreenMode(item, enabled: isScreenModeEnabled(item) == false)
                                    }) {
                                        Image(systemName: isScreenModeEnabled(item) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(isScreenModeEnabled(item) ? phosphorColor : phosphorDim)
                                    }
                                    .buttonStyle(.plain)

                                    Text(screenModeLabel(for: item))
                                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                    Spacer(minLength: 0)
                                    Button(action: { moveScreenMode(item, to: .bottom) }) {
                                        Image(systemName: "arrow.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(phosphorColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                )
                                .onDrop(of: [UTType.text], delegate: ScreenModeDropDelegate(
                                    target: item,
                                    items: $topScreenModeOrder,
                                    draggedItem: $draggedScreenMode,
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
                            ForEach(allBottomScreenModes, id: \.self) { item in
                                HStack(spacing: 12) {
                                    Text("≡")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .frame(width: 18, alignment: .center)
                                        .onDrag {
                                            draggedScreenMode = item
                                            return NSItemProvider(object: NSString(string: item.key))
                                        }
                                    Button(action: {
                                        setScreenMode(item, enabled: isScreenModeEnabled(item) == false)
                                    }) {
                                        Image(systemName: isScreenModeEnabled(item) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(isScreenModeEnabled(item) ? phosphorColor : phosphorDim)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 22, alignment: .center)
                                    Text(screenModeLabel(for: item))
                                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .frame(width: 210, alignment: .leading)

                                    Spacer(minLength: 0)

                                    if item == .utility(.games) {
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

                                    Button(action: { moveScreenMode(item, to: .top) }) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(phosphorColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorColor.opacity(0.2), lineWidth: 1)
                                )
                                .onDrop(of: [UTType.text], delegate: ScreenModeDropDelegate(
                                    target: item,
                                    items: $bottomScreenModeOrder,
                                    draggedItem: $draggedScreenMode,
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
        if enabledTopModes.contains(topScreenTopMode) == false, let fallback = orderedEnabledTopModes().first {
            topScreenTopMode = fallback
            if topScreenSelectedMode.isTopFamily {
                topScreenSelectedMode = .top(fallback)
            }
        }
        if enabledTopModes.contains(bottomScreenTopMode) == false, let fallback = orderedEnabledTopModes().first {
            bottomScreenTopMode = fallback
            if bottomScreenSelectedMode.isTopFamily {
                bottomScreenSelectedMode = .top(fallback)
            }
        }
    }

    func setUtilityMode(_ mode: UtilityMode, enabled: Bool) {
        if enabled {
            enabledUtilityModes.insert(mode)
        } else if enabledUtilityModes.count > 1 {
            enabledUtilityModes.remove(mode)
        }
        if enabledUtilityModes.contains(topScreenUtilityMode) == false, let fallback = orderedEnabledUtilityModes().first {
            topScreenUtilityMode = fallback
            if topScreenSelectedMode.isTopFamily == false {
                topScreenSelectedMode = .utility(fallback)
            }
            handleUtilityModeActivation(fallback)
        }
        if enabledUtilityModes.contains(bottomScreenUtilityMode) == false, let fallback = orderedEnabledUtilityModes().first {
            bottomScreenUtilityMode = fallback
            if bottomScreenSelectedMode.isTopFamily == false {
                bottomScreenSelectedMode = .utility(fallback)
            }
            handleUtilityModeActivation(fallback)
        }
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

        if let storedTopScreenOrder = defaults.array(forKey: "utilclock.topScreenModeOrder") as? [String] {
            let restored = storedTopScreenOrder.compactMap(screenModeItem(forKey:))
            let missing = ScreenModeItem.allCases.filter { restored.contains($0) == false && bottomScreenModeOrder.contains($0) == false }
            let merged = restored + missing
            if merged.isEmpty == false {
                topScreenModeOrder = merged
            }
        } else {
            topScreenModeOrder = topModeOrder.map { .top($0) }
        }

        if let storedBottomScreenOrder = defaults.array(forKey: "utilclock.bottomScreenModeOrder") as? [String] {
            let restored = storedBottomScreenOrder.compactMap(screenModeItem(forKey:))
            let missing = ScreenModeItem.allCases.filter { restored.contains($0) == false && topScreenModeOrder.contains($0) == false }
            let merged = restored + missing
            if merged.isEmpty == false {
                bottomScreenModeOrder = merged
            }
        } else {
            bottomScreenModeOrder = utilityModeOrder.map { .utility($0) }
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

        weatherManualLocationName = defaults.string(forKey: "utilclock.weather.manualLocationName")
        if defaults.object(forKey: "utilclock.weather.manualLatitude") != nil,
           defaults.object(forKey: "utilclock.weather.manualLongitude") != nil {
            weatherManualLatitude = defaults.double(forKey: "utilclock.weather.manualLatitude")
            weatherManualLongitude = defaults.double(forKey: "utilclock.weather.manualLongitude")
            if let manualName = weatherManualLocationName, manualName.isEmpty == false {
                weatherLocationName = manualName
                weatherLatitude = weatherManualLatitude
                weatherLongitude = weatherManualLongitude
            }
        } else {
            weatherManualLatitude = nil
            weatherManualLongitude = nil
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

        topScreenModeOrder = normalizedScreenModeOrder(
            topScreenModeOrder,
            excluding: []
        )
        bottomScreenModeOrder = normalizedScreenModeOrder(
            bottomScreenModeOrder,
            excluding: topScreenModeOrder
        )

        let assignedItems = Set(topScreenModeOrder + bottomScreenModeOrder)
        let missingItems = ScreenModeItem.allCases.filter { assignedItems.contains($0) == false }
        if missingItems.isEmpty == false {
            bottomScreenModeOrder.append(contentsOf: missingItems)
        }

        let defaultTopMode = orderedEnabledTopModes().first ?? .clock
        let defaultUtilityMode = orderedEnabledUtilityModes().first ?? .audio

        topScreenSelectedMode = firstEnabledMode(in: topScreenModeOrder) ?? .top(defaultTopMode)
        bottomScreenSelectedMode = firstEnabledMode(in: bottomScreenModeOrder) ?? .utility(defaultUtilityMode)

        topScreenTopMode = defaultTopMode
        bottomScreenTopMode = defaultTopMode
        topScreenUtilityMode = defaultUtilityMode
        bottomScreenUtilityMode = defaultUtilityMode

        if case .top(let mode) = topScreenSelectedMode {
            topScreenTopMode = mode
        }
        if case .top(let mode) = bottomScreenSelectedMode {
            bottomScreenTopMode = mode
        }
        if case .utility(let mode) = topScreenSelectedMode {
            topScreenUtilityMode = mode
        }
        if case .utility(let mode) = bottomScreenSelectedMode {
            bottomScreenUtilityMode = mode
        }
    }

    func normalizedScreenModeOrder(_ items: [ScreenModeItem], excluding excludedItems: [ScreenModeItem]) -> [ScreenModeItem] {
        var seen = Set(excludedItems)
        return items.filter { item in
            guard seen.contains(item) == false else { return false }
            seen.insert(item)
            return true
        }
    }

    func saveModeVisibilitySettings() {
        let defaults = UserDefaults.standard
        defaults.set(displayPalette.rawValue, forKey: "utilclock.displayPalette")
        defaults.set(orderedEnabledTopModes().map(\.key), forKey: "utilclock.enabledTopModes")
        defaults.set(orderedEnabledUtilityModes().map(\.key), forKey: "utilclock.enabledUtilityModes")
        defaults.set(topModeOrder.map(\.key), forKey: "utilclock.topModeOrder")
        defaults.set(utilityModeOrder.map(\.key), forKey: "utilclock.utilityModeOrder")
        defaults.set(topScreenModeOrder.map(\.key), forKey: "utilclock.topScreenModeOrder")
        defaults.set(bottomScreenModeOrder.map(\.key), forKey: "utilclock.bottomScreenModeOrder")
        defaults.set(max(1, min(4, pongFieldSizeLevel)), forKey: "utilclock.pongFieldSizeLevel")
        defaults.set(max(1, min(4, snakeBoardSizeLevel)), forKey: "utilclock.snakeBoardSizeLevel")
        defaults.set(max(1, min(9, arkanoidPaddleSizeLevel)), forKey: "utilclock.arkanoidPaddleSizeLevel")
        defaults.set(artilleryWindEnabled, forKey: "utilclock.artilleryWindEnabled")
        defaults.set(gameHighscoresByKey, forKey: "utilclock.gameHighscores")
        defaults.set(preferredFullscreen, forKey: preferredFullscreenKey)
        defaults.set(menuBarOnlyMode, forKey: menuBarOnlyModeKey)
        defaults.set(weatherManualLocationName, forKey: "utilclock.weather.manualLocationName")
        defaults.set(weatherManualLatitude, forKey: "utilclock.weather.manualLatitude")
        defaults.set(weatherManualLongitude, forKey: "utilclock.weather.manualLongitude")
    }

    var weatherManualLocationSummary: String {
        if let name = weatherManualLocationName, name.isEmpty == false {
            return "Ubicacion actual del tiempo: \(name)"
        }
        return "Ubicacion actual del tiempo: sin configurar"
    }

    #if os(macOS)
    func applyManualWeatherLocationSuggestion(_ suggestion: WeatherLocationSuggestion) {
        weatherLocationSearch.resolve(suggestion) { result in
            Task { @MainActor in
                switch result {
                case .success(let resolvedLocation):
                    weatherManualLocationName = resolvedLocation.locationName
                    weatherManualLatitude = resolvedLocation.latitude
                    weatherManualLongitude = resolvedLocation.longitude
                    weatherLatitude = resolvedLocation.latitude
                    weatherLongitude = resolvedLocation.longitude
                    weatherLocationName = resolvedLocation.locationName
                    weatherLastRefresh = nil
                    weatherRetryNotBefore = nil
                    weatherErrorText = nil
                    weatherLocationSearch.query = resolvedLocation.locationName
                    weatherLocationSearch.suggestions = []
                    saveModeVisibilitySettings()
                    refreshWeatherDataIfNeeded(force: true)
                case .failure(let error):
                    weatherErrorText = error.localizedDescription
                }
            }
        }
    }
    #endif

    func clearManualWeatherLocation() {
        weatherManualLocationName = nil
        weatherManualLatitude = nil
        weatherManualLongitude = nil
        weatherLatitude = nil
        weatherLongitude = nil
        weatherLocationName = ""
        weatherCurrentTemperatureC = nil
        weatherCurrentWeatherCode = 0
        weatherCurrentWindKmh = nil
        weatherTodayMinC = nil
        weatherTodayMaxC = nil
        weatherForecastDays = []
        weatherLastRefresh = nil
        weatherRetryNotBefore = nil
        weatherLoading = false
        weatherErrorText = nil
        weatherLocationSearch.clear()
        saveModeVisibilitySettings()
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
        if isGameActive(.artillery) {
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
