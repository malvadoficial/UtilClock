import SwiftUI

extension ContentView {
    var infoLauncherView: some View {
        GeometryReader { geometry in
            let spacing = max(10, min(18, geometry.size.width * 0.018))
            let cardCorner = CGFloat(12)
            let cardIconSize = max(30, min(46, geometry.size.width * 0.036))
            let cardTitleSize = max(18, min(28, geometry.size.width * 0.022))
            let horizontalPadding = CGFloat(24)
            let cardHeight = max(110, min(150, geometry.size.height * 0.38))
            let itemCount = CGFloat(InfoMode.allCases.count)
            let cardWidth = max(120, min(220, (geometry.size.width - (horizontalPadding * 2) - (spacing * max(0, itemCount - 1))) / max(1, itemCount)))

            HStack(spacing: spacing) {
                ForEach(InfoMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedInfoMode = mode
                        syncInfoActivation()
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: infoIcon(for: mode))
                                .font(.system(size: cardIconSize, weight: .semibold))
                                .foregroundStyle(phosphorColor)

                            Text(infoTitle(for: mode))
                                .font(.system(size: cardTitleSize, weight: .semibold, design: .monospaced))
                                .foregroundStyle(phosphorColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .minimumScaleFactor(0.55)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .background(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                .stroke(phosphorColor.opacity(0.42), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
        }
    }

    func infoTitle(for mode: InfoMode) -> String {
        switch mode {
        case .todayInHistory:
            return L10n.modeTodayInHistory
        case .musicThought:
            return L10n.modeMusicThought
        case .rae:
            return L10n.modeRAE
        }
    }

    func infoIcon(for mode: InfoMode) -> String {
        switch mode {
        case .todayInHistory:
            return "calendar"
        case .musicThought:
            return "quote.bubble"
        case .rae:
            return "book.closed"
        }
    }

    func isInfoActive(_ mode: InfoMode) -> Bool {
        utilityMode == .info && selectedInfoMode == mode
    }

    func syncInfoActivation() {
        if isInfoActive(.todayInHistory) {
            activateTodayInHistoryMode()
        } else {
            deactivateTodayInHistoryMode()
        }

        if isInfoActive(.musicThought) {
            activateMusicThoughtMode()
        } else {
            deactivateMusicThoughtMode()
        }
    }

    var musicLauncherView: some View {
        GeometryReader { geometry in
            let spacing = max(10, min(18, geometry.size.width * 0.018))
            let cardCorner = CGFloat(12)
            let cardIconSize = max(30, min(46, geometry.size.width * 0.036))
            let cardTitleSize = max(18, min(28, geometry.size.width * 0.022))
            let horizontalPadding = CGFloat(24)
            let itemCount = CGFloat(MusicMode.allCases.count)
            let cardWidth = max(120, min(220, (geometry.size.width - (horizontalPadding * 2) - (spacing * max(0, itemCount - 1))) / max(1, itemCount)))
            let cardHeight = max(110, min(150, geometry.size.height * 0.38))

            HStack(spacing: spacing) {
                ForEach(MusicMode.allCases, id: \.self) { mode in
                    Button(action: {
                        selectedMusicMode = mode
                        syncMusicActivation()
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: musicIcon(for: mode))
                                .font(.system(size: cardIconSize, weight: .semibold))
                                .foregroundStyle(phosphorColor)

                            Text(musicTitle(for: mode))
                                .font(.system(size: cardTitleSize, weight: .semibold, design: .monospaced))
                                .foregroundStyle(phosphorColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .minimumScaleFactor(0.55)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .background(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                .stroke(phosphorColor.opacity(0.42), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
        }
    }

    func musicTitle(for mode: MusicMode) -> String {
        switch mode {
        case .tuner:
            return L10n.modeTuner
        case .chordFinder:
            return L10n.modeChordFinder
        case .chordDetect:
            return L10n.modeChordDetect
        case .metronome:
            return L10n.modeMetronome
        case .tapTempo:
            return L10n.modeTapTempo
        }
    }

    func musicIcon(for mode: MusicMode) -> String {
        switch mode {
        case .tuner:
            return "tuningfork"
        case .chordFinder:
            return "guitars"
        case .chordDetect:
            return "waveform.and.magnifyingglass"
        case .metronome:
            return "metronome"
        case .tapTempo:
            return "hand.tap"
        }
    }

    func isMusicActive(_ mode: MusicMode) -> Bool {
        utilityMode == .music && selectedMusicMode == mode
    }

    func syncMusicActivation() {
        if isMusicActive(.tuner) || isMusicActive(.chordDetect) {
            tunerEngine.refreshInputs()
            tunerEngine.start()
        } else {
            tunerEngine.stop()
        }

        if isMusicActive(.chordFinder) {
            refreshChordFinder()
        }
        
        #if os(macOS)
        if isMusicActive(.tapTempo) == false {
            deactivateTapTempoMode()
        }
        #endif
    }
}
