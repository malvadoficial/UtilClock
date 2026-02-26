import SwiftUI
#if os(macOS)
import AppKit
import AVFoundation
import ServiceManagement
#endif

struct WeatherDayForecast: Identifiable {
    let id = UUID()
    let date: Date
    let minC: Double
    let maxC: Double
    let weatherCode: Int
}

private struct IPAPILocationResponse: Decodable {
    let city: String?
    let country_name: String?
    let latitude: Double?
    let longitude: Double?
}

private struct OpenMeteoForecastResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double?
        let weather_code: Int?
        let wind_speed_10m: Double?
    }

    struct Daily: Decodable {
        let time: [String]?
        let weather_code: [Int]?
        let temperature_2m_max: [Double]?
        let temperature_2m_min: [Double]?
    }

    let current: Current?
    let daily: Daily?
}

extension ContentView {

    var displayedSecondsText: String {
        switch topMode {
        case .clock:
            return viewModel.secondsText
        case .worldClock:
            return worldClockSecondsText
        case .calendar:
            return viewModel.secondsText
        case .weather:
            return viewModel.secondsText
        case .fullClock:
            return viewModel.secondsText
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

    func weatherSymbolName(code: Int, windKmh: Double?) -> String {
        if let windKmh, windKmh >= 36 {
            return "wind"
        }
        switch code {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51...57:
            return "cloud.drizzle.fill"
        case 61...67, 80...82:
            return "cloud.rain.fill"
        case 71...77, 85, 86:
            return "snow"
        case 95...99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.sun.fill"
        }
    }

    func weatherDayLabel(for date: Date) -> String {
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: date)
        let isSpanish = Locale.preferredLanguages.first?.lowercased().hasPrefix("es") ?? false
        if isSpanish {
            let labels = ["Dom", "Lun", "Mar", "Mie", "Jue", "Vie", "Sab"]
            return labels[max(0, min(6, weekday - 1))]
        } else {
            let labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return labels[max(0, min(6, weekday - 1))]
        }
    }

    var topWeatherFuture5Days: [WeatherDayForecast] {
        Array(weatherForecastDays.dropFirst().prefix(5))
    }

    @ViewBuilder
    func topWeatherTodayPanel(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: weatherSymbolName(code: weatherCurrentWeatherCode, windKmh: weatherCurrentWindKmh))
                .font(.system(size: max(56, driveTitleSize * 1.65), weight: .semibold))
                .foregroundStyle(phosphorColor)
                .frame(width: 84, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                Text(weatherLocationName)
                    .font(.system(size: max(20, dateSize * 1.28), weight: .semibold, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(weatherCurrentTemperatureC.map { "\(Int($0.rounded()))°C" } ?? "--°C")
                    .font(displayFont(size: max(52, driveTitleSize * 1.72), weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .multilineTextAlignment(.leading)

                Text("MIN \(weatherTodayMinC.map { "\(Int($0.rounded()))°" } ?? "--") · MAX \(weatherTodayMaxC.map { "\(Int($0.rounded()))°" } ?? "--")")
                    .font(.system(size: max(16, dateSize * 1.02), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func topWeatherForecastRows(dateSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(topWeatherFuture5Days) { day in
                HStack(spacing: 12) {
                    Text(weatherDayLabel(for: day.date))
                        .font(.system(size: max(15, dateSize * 0.98), weight: .semibold, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .frame(width: 54, alignment: .leading)

                    Image(systemName: weatherSymbolName(code: day.weatherCode, windKmh: nil))
                        .font(.system(size: max(20, dateSize * 1.15), weight: .semibold))
                        .foregroundStyle(phosphorColor)
                        .frame(width: 28, alignment: .center)

                    Text("MIN \(Int(day.minC.rounded()))°")
                        .font(.system(size: max(15, dateSize * 0.95), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("MAX \(Int(day.maxC.rounded()))°")
                        .font(.system(size: max(15, dateSize * 0.95), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(phosphorColor.opacity(0.24), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    func topWeatherView(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        GeometryReader { geometry in
            let wideLayout = geometry.size.width >= 760
            VStack(alignment: .leading, spacing: 14) {
                if wideLayout {
                    HStack(alignment: .top, spacing: 20) {
                        topWeatherTodayPanel(dateSize: dateSize, driveTitleSize: driveTitleSize)
                            .frame(maxWidth: geometry.size.width * 0.52, alignment: .leading)

                        topWeatherForecastRows(dateSize: dateSize)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    topWeatherTodayPanel(dateSize: dateSize, driveTitleSize: driveTitleSize)
                    topWeatherForecastRows(dateSize: dateSize)
                }

                if weatherLoading {
                    Text(L10n.weatherLoading)
                        .font(.system(size: max(13, dateSize * 0.86), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                } else if let weatherErrorText, weatherErrorText.isEmpty == false {
                    Text(weatherErrorText)
                        .font(.system(size: max(13, dateSize * 0.86), weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
            }
            .padding(.top, 30)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    func refreshWeatherDataIfNeeded(force: Bool) {
        if weatherLoading { return }
        if force == false, let last = weatherLastRefresh, Date().timeIntervalSince(last) < 900 {
            return
        }

        if let lat = weatherLatitude, let lon = weatherLongitude {
            fetchOpenMeteoWeather(latitude: lat, longitude: lon)
        } else {
            fetchWeatherLocationAndThenForecast()
        }
    }

    func fetchWeatherLocationAndThenForecast() {
        weatherLoading = true
        weatherErrorText = nil
        guard let url = URL(string: "https://ipapi.co/json/") else {
            weatherLoading = false
            weatherErrorText = L10n.weatherError
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await MainActor.run {
                        weatherLoading = false
                        weatherErrorText = L10n.weatherError
                    }
                    return
                }
                let decoded = try JSONDecoder().decode(IPAPILocationResponse.self, from: data)
                guard let lat = decoded.latitude, let lon = decoded.longitude else {
                    await MainActor.run {
                        weatherLoading = false
                        weatherErrorText = L10n.weatherError
                    }
                    return
                }

                let locationName = [decoded.city, decoded.country_name]
                    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
                    .joined(separator: ", ")

                await MainActor.run {
                    weatherLatitude = lat
                    weatherLongitude = lon
                    weatherLocationName = locationName.isEmpty ? "-" : locationName
                }
                fetchOpenMeteoWeather(latitude: lat, longitude: lon)
            } catch {
                await MainActor.run {
                    weatherLoading = false
                    weatherErrorText = L10n.weatherError
                }
            }
        }
    }

    func fetchOpenMeteoWeather(latitude: Double, longitude: Double) {
        weatherLoading = true
        weatherErrorText = nil
        let query = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=6"
        guard let url = URL(string: query) else {
            weatherLoading = false
            weatherErrorText = L10n.weatherError
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    await MainActor.run {
                        weatherLoading = false
                        weatherErrorText = L10n.weatherError
                    }
                    return
                }

                let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
                let currentTemp = decoded.current?.temperature_2m
                let currentCode = decoded.current?.weather_code ?? 0
                let currentWind = decoded.current?.wind_speed_10m

                let times = decoded.daily?.time ?? []
                let codes = decoded.daily?.weather_code ?? []
                let maxs = decoded.daily?.temperature_2m_max ?? []
                let mins = decoded.daily?.temperature_2m_min ?? []
                let count = min(times.count, codes.count, maxs.count, mins.count)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]

                var forecasts: [WeatherDayForecast] = []
                forecasts.reserveCapacity(count)
                if count > 0 {
                    for i in 0..<count {
                        let date = formatter.date(from: times[i]) ?? Date()
                        forecasts.append(
                            WeatherDayForecast(
                                date: date,
                                minC: mins[i],
                                maxC: maxs[i],
                                weatherCode: codes[i]
                            )
                        )
                    }
                }

                await MainActor.run {
                    weatherCurrentTemperatureC = currentTemp
                    weatherCurrentWeatherCode = currentCode
                    weatherCurrentWindKmh = currentWind
                    weatherForecastDays = forecasts
                    weatherTodayMinC = forecasts.first?.minC
                    weatherTodayMaxC = forecasts.first?.maxC
                    weatherLastRefresh = Date()
                    weatherLoading = false
                    weatherErrorText = nil
                }
            } catch {
                await MainActor.run {
                    weatherLoading = false
                    weatherErrorText = L10n.weatherError
                }
            }
        }
    }

    var calendarDisplayedMonthDate: Date {
        let calendar = Calendar(identifier: .gregorian)
        let currentComponents = calendar.dateComponents([.year, .month], from: viewModel.now)
        let currentMonthDate = calendar.date(from: currentComponents) ?? viewModel.now
        return calendar.date(byAdding: .month, value: calendarMonthOffset, to: currentMonthDate) ?? currentMonthDate
    }

    var calendarDisplayedMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL"
        return formatter.string(from: calendarDisplayedMonthDate).capitalized
    }

    var calendarDisplayedYear: Int {
        Calendar(identifier: .gregorian).component(.year, from: calendarDisplayedMonthDate)
    }

    var calendarWeekdayHeaders: [String] {
        ["L", "M", "X", "J", "V", "S", "D"]
    }

    var calendarGridDays: [Int?] {
        let calendar = Calendar(identifier: .gregorian)
        let monthDate = calendarDisplayedMonthDate
        guard
            let dayRange = calendar.range(of: .day, in: .month, for: monthDate),
            let firstDayDate = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))
        else {
            return []
        }

        // Convert Apple weekday (1=Sunday) to Monday-first index (0...6).
        let firstWeekday = calendar.component(.weekday, from: firstDayDate)
        let leadingEmptyCount = (firstWeekday + 5) % 7
        var values: [Int?] = Array(repeating: nil, count: leadingEmptyCount)
        values.append(contentsOf: dayRange.map { Optional($0) })
        while values.count % 7 != 0 {
            values.append(nil)
        }
        return values
    }

    func isCalendarToday(day: Int) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let shown = calendar.dateComponents([.year, .month], from: calendarDisplayedMonthDate)
        let now = calendar.dateComponents([.year, .month, .day], from: viewModel.now)
        return shown.year == now.year && shown.month == now.month && day == now.day
    }

    func calendarPreviousMonth() {
        calendarMonthOffset -= 1
    }

    func calendarNextMonth() {
        calendarMonthOffset += 1
    }

    func calendarGoToCurrentMonth() {
        calendarMonthOffset = 0
    }

    @ViewBuilder
    func topCalendarView(dateSize: CGFloat) -> some View {

        // 1) factor para agrandar SOLO la rejilla (headers + días)
        let gridScale: CGFloat = 1.40   // prueba 1.15–1.40

        // 2) columnas más “anchas”
        let columns = Array(repeating: GridItem(.flexible(minimum: 24 * gridScale), spacing: 8 * gridScale), count: 7)

        VStack(spacing: 8) {

            // --- TU HEADER (mes/año + flechas) IGUAL ---
            HStack(spacing: 12) {
                // ...
            }
            .padding(.top, 2)

            // --- SOLO ESTO MÁS GRANDE ---
            LazyVGrid(columns: columns, spacing: 6 * gridScale) {

                ForEach(calendarWeekdayHeaders, id: \.self) { dayName in
                    Text(dayName)
                        .font(.system(size: max(11, dateSize * (0.80 * gridScale)),
                                      weight: .semibold, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(calendarGridDays.enumerated()), id: \.offset) { _, value in
                    if let dayValue = value {
                        let isToday = isCalendarToday(day: dayValue)

                        Text("\(dayValue)")
                            .font(.system(size: max(11, dateSize * (0.82 * gridScale)),
                                          weight: .medium, design: .monospaced))
                            .foregroundStyle(isToday ? Color.black : phosphorDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            // 3) celdas más grandes
                            .frame(width: 30 * gridScale, height: 24 * gridScale)
                            .background(
                                ZStack {
                                    if isToday {
                                        Circle()
                                            .fill(phosphorColor.opacity(0.95))
                                        Circle()
                                            .stroke(Color.white.opacity(0.95), lineWidth: 1.3)
                                    }
                                }
                            )
                    } else {
                        Text(" ")
                            .frame(width: 30 * gridScale, height: 24 * gridScale)
                    }
                }
            }
            // 4) permitir que el grid sea más ancho
            .frame(maxWidth: 320 * gridScale)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    struct WorldCity {
        let code: String
        let timeZoneID: String
    }

    var worldCities: [WorldCity] {
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

    var selectedWorldCity: WorldCity {
        guard worldCities.isEmpty == false else {
            return WorldCity(code: "UTC", timeZoneID: "UTC")
        }
        let safeIndex = min(max(selectedWorldCityIndex, 0), worldCities.count - 1)
        return worldCities[safeIndex]
    }

    var worldClockCityCode: String {
        selectedWorldCity.code
    }

    var worldClockHourMinuteText: String {
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

    var worldClockSecondsText: String {
        guard let timeZone = TimeZone(identifier: selectedWorldCity.timeZoneID) else {
            return "--"
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.second], from: viewModel.now)
        let seconds = components.second ?? 0
        return String(format: "%02d", seconds)
    }

    func rotateWorldCityForward() {
        guard worldCities.isEmpty == false else { return }
        selectedWorldCityIndex = (selectedWorldCityIndex + 1) % worldCities.count
    }

    func rotateWorldCityBackward() {
        guard worldCities.isEmpty == false else { return }
        selectedWorldCityIndex = (selectedWorldCityIndex - 1 + worldCities.count) % worldCities.count
    }

    var uptimeText: (hourMinute: String, seconds: String) {
        let totalSeconds = max(0, Int(ProcessInfo.processInfo.systemUptime))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (
            hourMinute: "\(hours):" + String(format: "%02d", minutes),
            seconds: String(format: "%02d", seconds)
        )
    }

    var stopwatchText: (hourMinute: String, seconds: String) {
        let display = stopwatchDisplayValues(at: Date())
        return (
            hourMinute: "\(display.minutes):" + String(format: "%02d", display.seconds),
            seconds: String(format: "%02d", display.centiseconds)
        )
    }

    var stopwatchPrimaryButtonTitle: String {
        (stopwatchRunning || stopwatchPrestartInProgress) ? L10n.stop : L10n.start
    }

    var stopwatchPreButtonTitle: String {
        "\(L10n.stopwatchPrecountdownShort) \(stopwatchPrestartCountdownEnabled ? "on" : "off")"
    }

    var countdownPrimaryButtonTitle: String {
        countdownRunning ? "pausa" : L10n.start
    }

    var countdownText: (hourMinute: String, seconds: String) {
        let totalSeconds = max(0, countdownDisplayTotalSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return (
            hourMinute: "\(hours):" + String(format: "%02d", minutes),
            seconds: String(format: "%02d", seconds)
        )
    }

    func countdownButton(title: String, size: CGFloat, action: @escaping () -> Void) -> some View {
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

    func startStopwatch() {
        guard stopwatchRunning == false else { return }
        guard stopwatchPrestartInProgress == false else { return }

        if stopwatchPrestartCountdownEnabled {
            startStopwatchPrestartCountdown()
            return
        }
        beginStopwatchRun()
    }

    func toggleStopwatchRunState() {
        if stopwatchRunning || stopwatchPrestartInProgress {
            stopStopwatch()
        } else {
            startStopwatch()
        }
    }

    func stopStopwatch() {
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

    func resetStopwatch() {
        cancelStopwatchPrestartCountdown()
        stopwatchRunning = false
        stopwatchAccumulatedCentiseconds = 0
        stopwatchStartDate = nil
    }

    func stopwatchDisplayValues(at referenceDate: Date) -> (minutes: Int, seconds: Int, centiseconds: Int) {
        let totalCentiseconds = stopwatchDisplayTotalCentiseconds(at: referenceDate)
        let minutes = totalCentiseconds / 6000
        let seconds = (totalCentiseconds / 100) % 60
        let centiseconds = totalCentiseconds % 100
        return (minutes, seconds, centiseconds)
    }

    func stopwatchDisplayTotalCentiseconds(at referenceDate: Date) -> Int {
        var totalCentiseconds = stopwatchAccumulatedCentiseconds
        if stopwatchRunning, let startDate = stopwatchStartDate {
            totalCentiseconds += max(0, Int((referenceDate.timeIntervalSince(startDate) * 100).rounded(.down)))
        }
        return max(0, totalCentiseconds)
    }

    func beginStopwatchRun() {
        stopwatchStartDate = Date()
        stopwatchRunning = true
    }

    func startStopwatchPrestartCountdown() {
        cancelStopwatchPrestartCountdown()
        stopwatchPrestartInProgress = true
        prepareCountdownBeepPlayerIfNeeded()

        stopwatchPrestartTask = Task { @MainActor in
            for value in stride(from: 3, through: 1, by: -1) {
                stopwatchPrestartDisplayValue = value
                playCountdownFinalSecondsBeep()
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

    func cancelStopwatchPrestartCountdown() {
        stopwatchPrestartTask?.cancel()
        stopwatchPrestartTask = nil
        stopwatchPrestartInProgress = false
        stopwatchPrestartDisplayValue = nil
    }

    func startCountdown() {
        let configured = countdownConfiguredTotalSeconds
        if configured > 0 && (countdownInitialSeconds == 0 || countdownRemainingSeconds == 0 || configured != countdownInitialSeconds) {
            countdownInitialSeconds = configured
            countdownRemainingSeconds = configured
        }

        if countdownRemainingSeconds > 0 {
            countdownRunning = true
        }
    }

    func toggleCountdownRunState() {
        if countdownRunning {
            countdownRunning = false
        } else {
            startCountdown()
        }
    }

    func stopCountdown() {
        countdownRunning = false
        if countdownInitialSeconds == 0 {
            countdownInitialSeconds = countdownConfiguredTotalSeconds
        }
        countdownRemainingSeconds = countdownInitialSeconds
    }

    func resetCountdown() {
        countdownRunning = false
        countdownSetHours = 0
        countdownSetMinutes = 0
        countdownSetSeconds = 0
        countdownInitialSeconds = 0
        countdownRemainingSeconds = 0
    }

    func tickCountdown() {
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
    func playCountdownFinalSecondsBeep() {
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

    func prepareCountdownBeepPlayerIfNeeded() {
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

    func incrementCountdownHour() {
        guard countdownRunning == false else { return }
        countdownSetHours = (countdownSetHours + 1) % 24
        syncCountdownFromSetValues()
    }

    func decrementCountdownHour() {
        guard countdownRunning == false else { return }
        countdownSetHours = (countdownSetHours + 23) % 24
        syncCountdownFromSetValues()
    }

    func incrementCountdownMinute() {
        guard countdownRunning == false else { return }
        countdownSetMinutes = (countdownSetMinutes + 1) % 60
        syncCountdownFromSetValues()
    }

    func decrementCountdownMinute() {
        guard countdownRunning == false else { return }
        countdownSetMinutes = (countdownSetMinutes + 59) % 60
        syncCountdownFromSetValues()
    }

    func incrementCountdownSecond() {
        guard countdownRunning == false else { return }
        countdownSetSeconds = (countdownSetSeconds + 1) % 60
        syncCountdownFromSetValues()
    }

    func decrementCountdownSecond() {
        guard countdownRunning == false else { return }
        countdownSetSeconds = (countdownSetSeconds + 59) % 60
        syncCountdownFromSetValues()
    }

    func incrementAlarmHour() {
        alarmSetHours = (alarmSetHours + 1) % 24
    }

    func decrementAlarmHour() {
        alarmSetHours = (alarmSetHours + 23) % 24
    }

    func incrementAlarmMinute() {
        alarmSetMinutes = (alarmSetMinutes + 1) % 60
    }

    func decrementAlarmMinute() {
        alarmSetMinutes = (alarmSetMinutes + 59) % 60
    }

    func syncCountdownFromSetValues() {
        countdownInitialSeconds = countdownConfiguredTotalSeconds
        countdownRemainingSeconds = countdownInitialSeconds
    }

    var countdownConfiguredTotalSeconds: Int {
        (countdownSetHours * 3600) + (countdownSetMinutes * 60) + countdownSetSeconds
    }

    var countdownDisplayTotalSeconds: Int {
        if countdownRunning {
            return countdownRemainingSeconds
        }
        if countdownRemainingSeconds > 0 {
            return countdownRemainingSeconds
        }
        return countdownConfiguredTotalSeconds
    }

    var countdownDisplayHours: Int {
        countdownDisplayTotalSeconds / 3600
    }

    var countdownDisplayMinutes: Int {
        (countdownDisplayTotalSeconds % 3600) / 60
    }

    var countdownDisplaySeconds: Int {
        countdownDisplayTotalSeconds % 60
    }

    func syncAlarmToCurrentTimeIfUnset() {
        guard alarmSetHours == 0, alarmSetMinutes == 0 else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: viewModel.now)
        alarmSetHours = components.hour ?? 0
        alarmSetMinutes = components.minute ?? 0
    }

    func tickScheduledAlarm(now: Date) {
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

    func incrementMetronomeBPM() {
        metronomeBPM = min(300, metronomeBPM + 1)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    func decrementMetronomeBPM() {
        metronomeBPM = max(20, metronomeBPM - 1)
        if metronomeRunning {
            metronomeBeatIndex = 0
            restartMetronomeTimer()
        }
    }

    var allowedMetronomeNumerators: [Int] { [2, 3, 4, 5, 6, 7, 8] }

    var allowedMetronomeDenominators: [Int] { [2, 4, 8, 16] }

    func rotateMetronomeNumeratorForward() {
        rotateMetronomeValueForward(current: metronomeNumerator, values: allowedMetronomeNumerators) { next in
            metronomeNumerator = next
        }
    }

    func rotateMetronomeNumeratorBackward() {
        rotateMetronomeValueBackward(current: metronomeNumerator, values: allowedMetronomeNumerators) { next in
            metronomeNumerator = next
        }
    }

    func rotateMetronomeDenominatorForward() {
        rotateMetronomeValueForward(current: metronomeDenominator, values: allowedMetronomeDenominators) { next in
            metronomeDenominator = next
        }
    }

    func rotateMetronomeDenominatorBackward() {
        rotateMetronomeValueBackward(current: metronomeDenominator, values: allowedMetronomeDenominators) { next in
            metronomeDenominator = next
        }
    }

    func rotateMetronomeValueForward(current: Int, values: [Int], apply: (Int) -> Void) {
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

    func rotateMetronomeValueBackward(current: Int, values: [Int], apply: (Int) -> Void) {
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
    func refreshAvailableDisplays() {
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

    func savedStartupDisplayID() -> UInt32? {
        let defaults = UserDefaults.standard
        guard let value = defaults.object(forKey: startupDisplaySelectionKey) as? NSNumber else { return nil }
        return value.uint32Value
    }

    var savedStartupDisplayDescription: String {
        guard let savedID = savedStartupDisplayID() else {
            return "ninguna"
        }
        if let target = availableDisplayTargets.first(where: { $0.id == savedID }) {
            return "\(target.name) (\(target.resolutionText))"
        }
        return "id \(savedID)"
    }

    func applySavedStartupDisplaySelectionIfNeeded(remainingRetries: Int = 12) {
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

    func forgetSavedStartupDisplaySelection() {
        UserDefaults.standard.removeObject(forKey: startupDisplaySelectionKey)
        refreshAvailableDisplays()
    }

    func screenID(for screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    func moveToDisplayAndApplyPresentation(_ targetScreenID: UInt32) {
        guard let window = hostWindow else { return }
        guard let targetScreen = NSScreen.screens.first(where: { screenID(for: $0) == targetScreenID }) else { return }

        window.setFrame(targetScreen.frame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        showStartupScreenPicker = false
        UserDefaults.standard.set(Int(targetScreenID), forKey: startupDisplaySelectionKey)
        applyWindowPresentation(window: window, fullscreen: preferredFullscreen)
    }

    func ensureFullscreen(window: NSWindow, remainingRetries: Int) {
        guard remainingRetries > 0 else { return }
        if window.styleMask.contains(.fullScreen) { return }

        window.toggleFullScreen(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ensureFullscreen(window: window, remainingRetries: remainingRetries - 1)
        }
    }

    func ensureWindowed(window: NSWindow, remainingRetries: Int) {
        guard remainingRetries > 0 else { return }
        if window.styleMask.contains(.fullScreen) == false { return }

        window.toggleFullScreen(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            ensureWindowed(window: window, remainingRetries: remainingRetries - 1)
        }
    }

    func applyWindowPresentation(window: NSWindow, fullscreen: Bool) {
        if fullscreen {
            ensureFullscreen(window: window, remainingRetries: 8)
        } else {
            ensureWindowed(window: window, remainingRetries: 8)
        }
    }

    func setPreferredFullscreen(_ fullscreen: Bool) {
        preferredFullscreen = fullscreen
        saveModeVisibilitySettings()
        guard let window = hostWindow else { return }
        applyWindowPresentation(window: window, fullscreen: fullscreen)
    }

    func setMenuBarOnlyMode(_ enabled: Bool) {
        menuBarOnlyMode = enabled
        saveModeVisibilitySettings()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginErrorText = nil
        } catch {
            launchAtLoginErrorText = "error auto-inicio: \(error.localizedDescription)"
        }
        refreshLaunchAtLoginStatus()
    }

    func startCountdownAlarm() {
        startGlobalAlarm(duration: 30)
    }

    func startGlobalAlarm(duration: TimeInterval) {
        stopMetronome()
        tunerEngine.stop()
        deactivateTapTempoMode()
        deactivatePongMode()
        deactivateArkanoidMode()
        deactivateMissileCommandMode()
        deactivateSnakeMode()
        deactivateChromeDinoMode()
        deactivateTodayInHistoryMode()
        deactivateMusicThoughtMode()
        stopCountdownAlarmIfNeeded()
        countdownAlarmActive = true
        preAlarmTopMode = topMode
        preAlarmUtilityMode = utilityMode
        preAlarmMusicMode = selectedMusicMode
        preAlarmGameMode = selectedGameMode
        preAlarmInfoMode = selectedInfoMode

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

    func stopCountdownAlarmIfNeeded(restorePreviousModes: Bool = false) {
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
                }
                selectedMusicMode = previousUtilityMode == .music ? preAlarmMusicMode : nil
                selectedGameMode = previousUtilityMode == .games ? preAlarmGameMode : nil
                selectedInfoMode = previousUtilityMode == .info ? preAlarmInfoMode : nil
                syncMusicActivation()
                syncGameActivation()
                syncInfoActivation()
            }
        }
        preAlarmTopMode = nil
        preAlarmUtilityMode = nil
        preAlarmMusicMode = nil
        preAlarmGameMode = nil
        preAlarmInfoMode = nil
    }

    func startBundledAlarmAudioIfAvailable() -> Bool {
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

    func startMetronome() {
        guard metronomeRunning == false else { return }
        metronomeRunning = true
        metronomeBeatIndex = 0
        triggerMetronomePulse()
        restartMetronomeTimer()
    }

    func stopMetronome() {
        metronomeRunning = false
        metronomePulseActive = false
        metronomeBeatIndex = 0
        metronomeTimer?.setEventHandler {}
        metronomeTimer?.cancel()
        metronomeTimer = nil
    }

    func restartMetronomeTimer() {
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

    func triggerMetronomePulse() {
        let isStrongBeat = metronomeBeatIndex == 0
        metronomeBeatIndex = (metronomeBeatIndex + 1) % max(1, metronomeNumerator)
        metronomePulseActive = true
        playMetronomeTickSound(strong: isStrongBeat)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            metronomePulseActive = false
        }
    }

    func playMetronomeTickSound(strong: Bool) {
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

    func prepareMetronomeTickPlayersIfNeeded() {
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
    
    // MARK: - Full Clock View
    
    @ViewBuilder
    func fullClockView(dateSize: CGFloat, mainClockSize: CGFloat, secondsSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 30) {
            // Columna izquierda: Reloj y fecha
            VStack(alignment: .leading, spacing: 10) {
                // Hora actual
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    let hourMinute = viewModel.hourMinuteText
                    let components = hourMinute.components(separatedBy: ":")
                    let hourPart = components.first ?? "00"
                    let minutePart = components.count > 1 ? components[1] : "00"
                    
                    Text(hourPart)
                        .font(displayFont(size: max(44, mainClockSize * 0.63), weight: .bold))
                        .monospacedDigit()
                        .shadow(color: phosphorColor.opacity(0.8), radius: 6)
                    
                    Text(":")
                        .font(displayFont(size: max(44, mainClockSize * 0.63), weight: .bold))
                        .monospacedDigit()
                        .shadow(color: phosphorColor.opacity(0.8), radius: 6)
                        .opacity(timeSeparatorOpacity)
                    
                    Text(minutePart)
                        .font(displayFont(size: max(44, mainClockSize * 0.63), weight: .bold))
                        .monospacedDigit()
                        .shadow(color: phosphorColor.opacity(0.8), radius: 6)
                    
                    Text(viewModel.secondsText)
                        .font(displayFont(size: max(24, secondsSize * 0.65), weight: .bold))
                        .monospacedDigit()
                        .shadow(color: phosphorColor.opacity(0.7), radius: 4)
                }
                .foregroundStyle(phosphorColor)
                
                // Día completo
                Text(fullClockFullDateText)
                    .font(.system(size: max(14, dateSize * 1.0), weight: .medium, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Columna derecha: Calendario y clima
            VStack(alignment: .trailing, spacing: 10) {
                // Mini calendario
                fullClockMiniCalendar(dateSize: dateSize)
                
                // Info del clima
                if weatherCurrentTemperatureC != nil || weatherLocationName.isEmpty == false {
                    fullClockWeatherInfo(dateSize: dateSize, driveTitleSize: driveTitleSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    var fullClockFullDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES") // o "es"
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM yyyy")
        return formatter.string(from: viewModel.now)
    }
    
    @ViewBuilder
    func fullClockMiniCalendar(dateSize: CGFloat) -> some View {
        let gridDays = calendarGridDays
        
        VStack(spacing: 5) {
            // Nombre del mes y año (más pequeño)
            Text("\(calendarDisplayedMonthName) \(calendarDisplayedYear)")
                .font(.system(size: max(13, dateSize * 0.92), weight: .bold, design: .monospaced))
                .foregroundStyle(phosphorColor)
            
            // Headers de días
            HStack(spacing: 2) {
                ForEach(calendarWeekdayHeaders, id: \.self) { dayName in
                    Text(dayName)
                        .font(.system(size: max(9, dateSize * 0.65), weight: .semibold, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .frame(minWidth: 18, maxWidth: .infinity)
                }
            }
            
            // Grid de días usando ForEach en filas
            let rows = stride(from: 0, to: gridDays.count, by: 7).map { startIndex in
                Array(gridDays[startIndex..<min(startIndex + 7, gridDays.count)])
            }
            
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { colIndex in
                        let index = rowIndex * 7 + colIndex
                        if index < gridDays.count, let dayValue = gridDays[index] {
                            let isToday = isCalendarToday(day: dayValue)
                            
                            Text("\(dayValue)")
                                .font(.system(size: max(10, dateSize * 0.72), weight: isToday ? .bold : .medium, design: .monospaced))
                                .foregroundStyle(isToday ? Color.black : phosphorColor)
                                .lineLimit(1)
                                .frame(minWidth: 18, maxWidth: .infinity, minHeight: 16)
                                .background(
                                    ZStack {
                                        if isToday {
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .fill(phosphorColor.opacity(0.95))
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .stroke(Color.white.opacity(0.9), lineWidth: 1.2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .stroke(phosphorDim.opacity(0.15), lineWidth: 0.5)
                                        }
                                    }
                                )
                        } else {
                            Text("")
                                .frame(minWidth: 18, maxWidth: .infinity, minHeight: 16)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(phosphorColor.opacity(0.3), lineWidth: 1.2)
        )
    }
    
    @ViewBuilder
    func fullClockWeatherInfo(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Ubicación (más grande)
            Text(weatherLocationName)
                .font(.system(size: max(14, dateSize * 1.0), weight: .medium, design: .monospaced))
                .foregroundStyle(phosphorColor)
                .lineLimit(1)
            
            // Fila: Icono y Temperatura juntos
            HStack(spacing: 10) {
                // Icono del clima
                Image(systemName: weatherSymbolName(code: weatherCurrentWeatherCode, windKmh: weatherCurrentWindKmh))
                    .font(.system(size: max(34, driveTitleSize * 1.15), weight: .semibold))
                    .foregroundStyle(phosphorColor)
                    .frame(width: 40)
                
                // Temperatura grande
                Text(weatherCurrentTemperatureC.map { "\(Int($0.rounded()))°C" } ?? "--°C")
                    .font(displayFont(size: max(28, driveTitleSize * 0.95), weight: .bold))
                    .foregroundStyle(phosphorColor)
            }
            
            // MIN/MAX horizontal (más grandes)
            HStack(spacing: 8) {
                Text("MIN \(weatherTodayMinC.map { "\(Int($0.rounded()))°" } ?? "--")")
                    .font(.system(size: max(11, dateSize * 0.78), weight: .regular, design: .monospaced))
                Text("MAX \(weatherTodayMaxC.map { "\(Int($0.rounded()))°" } ?? "--")")
                    .font(.system(size: max(11, dateSize * 0.78), weight: .regular, design: .monospaced))
            }
            .foregroundStyle(phosphorDim)
        }
        .padding(9)
        .background(Color.black.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(phosphorColor.opacity(0.3), lineWidth: 1)
        )
    }
    #endif
}

