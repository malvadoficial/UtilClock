import SwiftUI

extension ContentView {
    func isTopModeVisible(_ mode: TopClockMode) -> Bool {
        displayedTopMode(on: .top) == mode || displayedTopMode(on: .bottom) == mode
    }

    func isUtilityModeVisible(_ mode: UtilityMode) -> Bool {
        displayedUtilityMode(on: .top) == mode || displayedUtilityMode(on: .bottom) == mode
    }

    func screenShowingUtilityMode(_ mode: UtilityMode) -> ScreenSlot? {
        if displayedUtilityMode(on: .top) == mode { return .top }
        if displayedUtilityMode(on: .bottom) == mode { return .bottom }
        return nil
    }

    func screenShowingTopMode(_ mode: TopClockMode) -> ScreenSlot? {
        if displayedTopMode(on: .top) == mode { return .top }
        if displayedTopMode(on: .bottom) == mode { return .bottom }
        return nil
    }

    func syncVisibleModeState(forceWeatherRefresh: Bool = false, forceNetworkRefresh: Bool = true) {
        if isUtilityModeVisible(.music) == false {
            selectedMusicMode = nil
        }
        syncMusicActivation()

        if isUtilityModeVisible(.games) == false {
            selectedGameMode = nil
        }
        syncGameActivation()

        if isUtilityModeVisible(.info) == false {
            selectedInfoMode = nil
        }
        syncInfoActivation()

        if isUtilityModeVisible(.photos) {
            hydratePhotosSourcesIfNeeded()
        } else {
            stopPhotosSlideshow()
        }

        if isUtilityModeVisible(.videos) {
            hydrateVideosSourcesIfNeeded()
        } else {
            stopVideosPlayback()
        }

        if isUtilityModeVisible(.network) {
            refreshNetworkModeData(forcePublicIPRefresh: forceNetworkRefresh)
        }

        if isTopModeVisible(.weather) || isTopModeVisible(.fullClock) {
            refreshWeatherDataIfNeeded(force: forceWeatherRefresh)
        }
    }

    func displayedTopMode(on screen: ScreenSlot) -> TopClockMode? {
        let item = screen == .top ? topScreenSelectedMode : bottomScreenSelectedMode
        guard case .top = item else { return nil }
        return screen == .top ? topScreenTopMode : bottomScreenTopMode
    }

    func displayedUtilityMode(on screen: ScreenSlot) -> UtilityMode? {
        let item = screen == .top ? topScreenSelectedMode : bottomScreenSelectedMode
        guard case .utility = item else { return nil }
        return screen == .top ? topScreenUtilityMode : bottomScreenUtilityMode
    }

    func modeLabel(for screen: ScreenSlot) -> String {
        if let mode = displayedTopMode(on: screen) {
            return topModeLabel(for: mode)
        }
        if let mode = displayedUtilityMode(on: screen) {
            return utilityModeLabel(for: mode)
        }
        return screenModeLabel(for: screen == .top ? topScreenSelectedMode : bottomScreenSelectedMode)
    }

    func shouldHideModeSelectorTag(on screen: ScreenSlot) -> Bool {
        guard let mode = displayedUtilityMode(on: screen) else { return false }
        if mode == .music, selectedMusicMode != nil { return true }
        if mode == .games, selectedGameMode != nil { return true }
        if mode == .info, selectedInfoMode != nil { return true }
        if mode == .photos, photosIsRunning, splitFullscreenTarget == screenFullscreenTarget(screen) { return true }
        if mode == .videos, videosIsRunning, splitFullscreenTarget == screenFullscreenTarget(screen) { return true }
        return false
    }

    func screenFullscreenTarget(_ screen: ScreenSlot) -> SplitFullscreenTarget {
        screen == .top ? .top : .bottom
    }

    func displayedHourMinuteText(for mode: TopClockMode) -> String {
        switch mode {
        case .clock:
            return viewModel.hourMinuteText
        case .worldClock:
            return worldClockHourMinuteText
        case .calendar:
            return viewModel.hourMinuteText
        case .weather:
            return viewModel.hourMinuteText
        case .fullClock:
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

    func displayedSecondsText(for mode: TopClockMode) -> String {
        switch mode {
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

    func displayedHourMinuteParts(for mode: TopClockMode) -> (hours: String, minutes: String) {
        let text = displayedHourMinuteText(for: mode)
        guard let separator = text.firstIndex(of: ":") else {
            return (text, "00")
        }
        let hours = String(text[..<separator])
        let minutesStart = text.index(after: separator)
        let minutes = String(text[minutesStart...])
        return (hours, minutes)
    }

    func shouldBlinkTimeSeparator(for mode: TopClockMode) -> Bool {
        switch mode {
        case .clock, .worldClock, .uptime:
            return true
        case .calendar, .weather, .fullClock, .alarm:
            return false
        case .stopwatch:
            return stopwatchRunning
        case .countdown:
            return countdownRunning
        }
    }

    func timeSeparatorOpacity(for mode: TopClockMode) -> Double {
        guard shouldBlinkTimeSeparator(for: mode) else { return 1.0 }
        let second = Calendar.current.component(.second, from: viewModel.now)
        return second.isMultiple(of: 2) ? 1.0 : 0.18
    }

    @ViewBuilder
    func topModeContent(mode: TopClockMode, dateSize: CGFloat, mainClockSize: CGFloat, secondsSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        if mode == .calendar {
            topCalendarView(dateSize: dateSize)
        } else if mode == .weather {
            topWeatherView(dateSize: dateSize, driveTitleSize: driveTitleSize)
        } else if mode == .fullClock {
            fullClockView(dateSize: dateSize, mainClockSize: mainClockSize, secondsSize: secondsSize, driveTitleSize: driveTitleSize)
        } else if mode == .stopwatch {
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
                            .opacity(timeSeparatorOpacity(for: mode))

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
        } else if mode == .countdown {
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
                        .opacity(timeSeparatorOpacity(for: mode))

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
        } else if mode == .alarm {
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
                        .opacity(timeSeparatorOpacity(for: mode))

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
                let parts = displayedHourMinuteParts(for: mode)
                Text(parts.hours)
                    .font(displayFont(size: mainClockSize, weight: .bold))
                    .monospacedDigit()
                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                Text(":")
                    .font(displayFont(size: mainClockSize, weight: .bold))
                    .monospacedDigit()
                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)
                    .opacity(timeSeparatorOpacity(for: mode))

                Text(parts.minutes)
                    .font(displayFont(size: mainClockSize, weight: .bold))
                    .monospacedDigit()
                    .shadow(color: phosphorColor.opacity(0.8), radius: 8)

                Text(displayedSecondsText(for: mode))
                    .font(displayFont(size: secondsSize, weight: .bold))
                    .monospacedDigit()
                    .shadow(color: phosphorColor.opacity(0.7), radius: 6)

                if mode == .worldClock {
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
    }

    @ViewBuilder
    func utilityModeContent(mode: UtilityMode, dateSize: CGFloat, driveTitleSize: CGFloat, topHalfHeight: CGFloat) -> some View {
        #if os(macOS)
        Group {
            if mode == .audio {
                audioUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
            } else if mode == .music, selectedMusicMode == nil {
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
                            .overlay(
                                MouseClickCatcher(
                                    onLeftClick: { rotateChordVoicingForward() },
                                    onRightClick: { rotateChordVoicingBackward() }
                                )
                            )
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
            } else if isMusicActive(.tapTempo) {
                HStack(alignment: .center, spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(tapTempoPulseActive ? phosphorColor.opacity(0.22) : Color(red: 0.06, green: 0.15, blue: 0.09))
                        Circle()
                            .stroke(phosphorColor.opacity(0.65), lineWidth: 2)
                    }
                    .frame(width: topHalfHeight * 0.75, height: topHalfHeight * 0.75)
                    .shadow(color: phosphorColor.opacity(tapTempoPulseActive ? 0.55 : 0.18), radius: 12)

                    VStack(spacing: 12) {
                        Text("BPM")
                            .font(.system(size: max(14, dateSize * 1.05), weight: .medium, design: .monospaced))
                            .foregroundStyle(phosphorDim)

                        Text(tapTempoBPM > 0 ? String(format: "%.1f", tapTempoBPM) : "---")
                            .font(displayFont(size: max(44, driveTitleSize * 1.55), weight: .bold))
                            .foregroundStyle(phosphorColor)
                            .monospacedDigit()
                            .frame(minWidth: 140, minHeight: 52)

                        Button(action: {
                            registerTapTempoTap()
                        }) {
                            Text(L10n.tapTempoTap)
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
                        .keyboardShortcut(.space, modifiers: [])

                        Button(action: {
                            resetTapTempo()
                        }) {
                            Text(L10n.reset)
                                .font(.system(size: max(15, dateSize * 1.08), weight: .regular, design: .monospaced))
                                .foregroundStyle(phosphorDim)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: 190)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(phosphorDim.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PressableCountdownButtonStyle(phosphorColor: phosphorColor))

                        Text(tapTempoTaps.count > 0 ? "\(tapTempoTaps.count) \(tapTempoTaps.count == 1 ? L10n.tapTempoTapSingular : L10n.tapTempoTapPlural)" : " ")
                            .font(.system(size: max(13, dateSize * 0.92), weight: .regular, design: .monospaced))
                            .foregroundStyle(tapTempoTaps.count > 0 ? phosphorDim : Color.clear)
                            .frame(minHeight: 18)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if mode == .games {
                gamesView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if mode == .info, selectedInfoMode == nil {
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
            } else if mode == .teleprompter {
                teleprompterView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if mode == .cpu {
                cpuUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
            } else if mode == .apps {
                appsUtilityView(dateSize: dateSize)
            } else if mode == .network {
                networkUtilityView(dateSize: dateSize, driveTitleSize: driveTitleSize)
            } else if mode == .storage {
                storageUtilityView(rowFontSize: driveTitleSize)
            } else if mode == .photos {
                photosUtilityView(dateSize: dateSize)
            } else if mode == .videos {
                videosUtilityView(dateSize: dateSize)
            }
        }
        #endif
    }
}
