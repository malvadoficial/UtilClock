import SwiftUI
#if os(macOS)
import Foundation
#endif

extension ContentView {
    #if os(macOS)
    var isSpanishLanguage: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("es") == true
    }

    func localizedThisDayText(_ event: ThisDayEvent) -> String {
        isSpanishLanguage ? event.es : event.en
    }

    var todayMonthDay: (month: Int, day: Int) {
        let components = Calendar.current.dateComponents([.month, .day], from: viewModel.now)
        return (components.month ?? 1, components.day ?? 1)
    }

    var todayInHistoryLocalEvents: [ThisDayEvent] {
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

    var activeTodayInHistoryEvents: [ThisDayEvent] {
        guard todayEventsInitialLoadCompleted else { return [] }
        return todayInternetEvents.isEmpty ? todayInHistoryLocalEvents : todayInternetEvents
    }

    var rotatingTodayInHistoryEvents: [ThisDayEvent] {
        let source = activeTodayInHistoryEvents
        guard source.isEmpty == false else { return [] }
        let count = 5
        let offset = source.isEmpty ? 0 : (todayEventsRotationOffset % source.count)
        return (0..<count).map { source[($0 + offset) % source.count] }
    }

    var todayInHistoryView: some View {
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
                                .font(displayFont(size: 24, weight: .bold))
                                .foregroundStyle(phosphorColor)
                                .frame(width: 84, alignment: .leading)

                            Text(localizedThisDayText(event))
                                .font(.system(size: 28, weight: .regular, design: .monospaced))
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

    var activeMusicThoughtQuote: MusicThoughtQuote? {
        guard musicThoughtQuotes.isEmpty == false else { return nil }
        let index = max(0, musicThoughtIndex % musicThoughtQuotes.count)
        return musicThoughtQuotes[index]
    }

    var musicThoughtView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if musicThoughtLoading && musicThoughtQuotes.isEmpty {
                Text(isSpanishLanguage ? "cargando frases..." : "loading thoughts...")
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .padding(.horizontal, 18)
                    .padding(.top, 56)
            }

            if let quote = activeMusicThoughtQuote {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\"\(quote.quote)\"")
                            .font(.system(size: 30, weight: .medium, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(quote.author)
                            .font(displayFont(size: 21, weight: .bold))
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

    var raeView: some View {
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

    func activateTodayInHistoryMode() {
        startTodayInHistoryTimerIfNeeded()
        updateTodayInHistoryRotationForCurrentHour()
        fetchTodayInHistoryFromInternet(force: true)
    }

    func deactivateTodayInHistoryMode() {
        todayEventsTimer?.invalidate()
        todayEventsTimer = nil
    }

    func startTodayInHistoryTimerIfNeeded() {
        guard todayEventsTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { _ in
            updateTodayInHistoryRotationForCurrentHour()
            fetchTodayInHistoryFromInternet(force: false)
        }
        timer.tolerance = 30.0
        RunLoop.main.add(timer, forMode: .common)
        todayEventsTimer = timer
    }

    func updateTodayInHistoryRotationForCurrentHour() {
        let events = activeTodayInHistoryEvents
        guard events.isEmpty == false else {
            todayEventsRotationOffset = 0
            return
        }

        let blockSize = 5
        let hour = Calendar.current.component(.hour, from: Date())
        todayEventsRotationOffset = (hour * blockSize) % events.count
    }

    func advanceTodayInHistoryEventsBlock() {
        let events = activeTodayInHistoryEvents
        guard events.isEmpty == false else { return }
        let blockSize = 5
        todayEventsRotationOffset = (todayEventsRotationOffset + blockSize) % events.count
    }

    func fetchTodayInHistoryFromInternet(force: Bool) {
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

    func activateMusicThoughtMode() {
        if musicThoughtQuotes.count > 1 {
            let current = max(0, min(musicThoughtQuotes.count - 1, musicThoughtIndex))
            var next = Int.random(in: 0..<musicThoughtQuotes.count)
            if next == current {
                next = (next + 1) % musicThoughtQuotes.count
            }
            musicThoughtIndex = next
        }
        startMusicThoughtTimerIfNeeded()
        fetchMusicThoughtQuotes(force: true)
    }

    func deactivateMusicThoughtMode() {
        musicThoughtTimer?.invalidate()
        musicThoughtTimer = nil
    }

    func searchInRAE() {
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

    nonisolated static func runRAECurlSearch(term: String) -> String {
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

    nonisolated static func runCurl(url: String) -> String {
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

    nonisolated static func extractSuggestedRAEEntryURL(from raw: String) -> String? {
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

    nonisolated static func parseRAEScrapedLines(from raw: String, term: String, isSpanishLanguage: Bool) -> [String] {
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

    func startMusicThoughtTimerIfNeeded() {
        guard musicThoughtTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { _ in
            advanceMusicThoughtQuote()
            fetchMusicThoughtQuotes(force: false)
        }
        timer.tolerance = 30.0
        RunLoop.main.add(timer, forMode: .common)
        musicThoughtTimer = timer
    }

    func advanceMusicThoughtQuote() {
        guard musicThoughtQuotes.isEmpty == false else {
            fetchMusicThoughtQuotes(force: true)
            return
        }
        musicThoughtIndex = (musicThoughtIndex + 1) % max(1, musicThoughtQuotes.count)
    }

    func fetchMusicThoughtQuotes(force: Bool) {
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
                                musicThoughtIndex = parsed.indices.randomElement() ?? 0
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

    func parseMusicThoughtQuotes(from data: Data) -> [MusicThoughtQuote] {
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

    func cleanMusicThoughtHTMLFragment(_ fragment: String) -> String {
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
}
