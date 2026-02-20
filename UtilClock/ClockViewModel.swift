//
//  ClockViewModel.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import Foundation
import Combine

@MainActor
final class ClockViewModel: ObservableObject {
    @Published private(set) var now = Date()

    private let timerQueue = DispatchQueue(label: "utilclock.clock.timer", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastPublishedSecond: Int64 = -1
    private let timeFormatter: DateFormatter
    private let dateFormatter: DateFormatter

    var timeText: String {
        timeFormatter.string(from: now)
    }

    var hourMinuteText: String {
        String(timeText.prefix(5))
    }

    var secondsText: String {
        String(timeText.suffix(2))
    }

    var dateText: String {
        dateFormatter.string(from: now)
    }

    init() {
        timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = TimeZone.autoupdatingCurrent

        dateFormatter = DateFormatter()
        let preferredLanguage = Locale.preferredLanguages.first ?? Locale.autoupdatingCurrent.identifier
        dateFormatter.locale = Locale(identifier: preferredLanguage)
        dateFormatter.calendar = Calendar.autoupdatingCurrent
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM y")

        startTimer()
    }

    deinit {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func startTimer() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil

        now = Date()
        lastPublishedSecond = Int64(floor(now.timeIntervalSince1970))
        let newTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        newTimer.schedule(
            deadline: .now(),
            repeating: .milliseconds(120),
            leeway: .milliseconds(20)
        )
        newTimer.setEventHandler { [weak self] in
            guard let self else { return }
            let currentNow = Date()
            let currentSecond = Int64(floor(currentNow.timeIntervalSince1970))
            guard currentSecond != self.lastPublishedSecond else { return }
            self.lastPublishedSecond = currentSecond
            let snappedDate = Date(timeIntervalSince1970: TimeInterval(currentSecond))
            Task { @MainActor in
                self.now = snappedDate
            }
        }
        newTimer.resume()
        timer = newTimer
    }
}
