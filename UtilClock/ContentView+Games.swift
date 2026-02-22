import SwiftUI
#if os(macOS)
import AppKit
import QuartzCore
#endif

extension ContentView {
    var gamesView: some View {
        ZStack(alignment: .topLeading) {
            if let selectedGameMode {
                selectedGameView(selectedGameMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                gamesLauncherView
            }

            if selectedGameMode != nil {
                Button(action: {
                    selectedGameMode = nil
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
                .padding(.leading, 18)
                .padding(.top, 14)
            }
        }
    }

    @ViewBuilder
    func selectedGameView(_ mode: GameMode) -> some View {
        switch mode {
        case .pong:
            pongView
        case .arkanoid:
            arkanoidView
        case .missileCommand:
            missileCommandView
        case .snake:
            snakeView
        case .chromeDino:
            chromeDinoView
        case .tetris:
            tetrisView
        case .spaceInvaders:
            spaceInvadersView
        case .asteroids:
            asteroidsView
        case .tron:
            tronView
        case .pacman:
            pacmanView
        case .frogger:
            froggerView
        case .artillery:
            artilleryView
        }
    }

    func gameTitle(for mode: GameMode) -> String {
        switch mode {
        case .pong:
            return L10n.modePong
        case .arkanoid:
            return L10n.modeArkanoid
        case .missileCommand:
            return L10n.modeMissileCommand
        case .snake:
            return L10n.modeSnake
        case .chromeDino:
            return L10n.modeChromeDino
        case .tetris:
            return L10n.modeTetris
        case .spaceInvaders:
            return L10n.modeSpaceInvaders
        case .asteroids:
            return L10n.modeAsteroids
        case .tron:
            return L10n.modeTron
        case .pacman:
            return L10n.modePacman
        case .frogger:
            return L10n.modeFrogger
        case .artillery:
            return L10n.modeArtillery
        }
    }

    func gameIcon(for mode: GameMode) -> String {
        switch mode {
        case .pong:
            return "figure.table.tennis"
        case .arkanoid:
            return "rectangle.3.group.bubble.left.fill"
        case .missileCommand:
            return "scope"
        case .snake:
            return "scribble.variable"
        case .chromeDino:
            return "figure.run"
        case .tetris:
            return "square.grid.3x3.fill"
        case .spaceInvaders:
            return "sparkles.rectangle.stack"
        case .asteroids:
            return "circle.hexagongrid.fill"
        case .tron:
            return "point.3.connected.trianglepath.dotted"
        case .pacman:
            return "circle.dotted.circle"
        case .frogger:
            return "leaf.fill"
        case .artillery:
            return "scope"
        }
    }

    var gamesLauncherView: some View {
        GeometryReader { geometry in
            let spacing = max(10, min(18, geometry.size.width * 0.018))
            let cardCorner = CGFloat(12)
            let cardIconSize = max(30, min(46, geometry.size.width * 0.036))
            let cardTitleSize = max(18, min(28, geometry.size.width * 0.022))
            let horizontalPadding = CGFloat(24)
            let cardWidth = max(120, min(220, (geometry.size.width - (horizontalPadding * 2) - (spacing * 3)) / 4))
            let cardHeight = max(110, min(150, geometry.size.height * 0.38))
            let availableWidth = max(1, geometry.size.width - (horizontalPadding * 2))
            let columnsCount = max(1, min(4, Int((availableWidth + spacing) / (cardWidth + spacing))))
            let gridColumns = Array(
                repeating: GridItem(.fixed(cardWidth), spacing: spacing, alignment: .top),
                count: columnsCount
            )

            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, alignment: .center, spacing: spacing) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Button(action: {
                            selectedGameMode = mode
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: gameIcon(for: mode))
                                    .font(.system(size: cardIconSize, weight: .semibold))
                                    .foregroundStyle(phosphorColor)

                                Text(gameTitle(for: mode))
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
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 34)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    func isGameActive(_ mode: GameMode) -> Bool {
        utilityMode == .games && selectedGameMode == mode
    }

    func syncGameActivation() {
        if isGameActive(.pong) {
            activatePongMode()
        } else {
            deactivatePongMode()
        }

        if isGameActive(.arkanoid) {
            activateArkanoidMode()
        } else {
            deactivateArkanoidMode()
        }

        if isGameActive(.missileCommand) {
            activateMissileCommandMode()
        } else {
            deactivateMissileCommandMode()
        }

        if isGameActive(.snake) {
            activateSnakeMode()
        } else {
            deactivateSnakeMode()
        }

        if isGameActive(.chromeDino) {
            activateChromeDinoMode()
        } else {
            deactivateChromeDinoMode()
        }

        if isGameActive(.tetris) {
            activateTetrisMode()
        } else {
            deactivateTetrisMode()
        }

        if isGameActive(.spaceInvaders) {
            activateSpaceInvadersMode()
        } else {
            deactivateSpaceInvadersMode()
        }

        if isGameActive(.asteroids) {
            activateAsteroidsMode()
        } else {
            deactivateAsteroidsMode()
        }

        if isGameActive(.tron) {
            activateTronMode()
        } else {
            deactivateTronMode()
        }

        if isGameActive(.pacman) {
            activatePacmanMode()
        } else {
            deactivatePacmanMode()
        }

        if isGameActive(.frogger) {
            activateFroggerMode()
        } else {
            deactivateFroggerMode()
        }

        if isGameActive(.artillery) {
            activateArtilleryMode()
        } else {
            deactivateArtilleryMode()
        }
    }

    var pongFieldWidthScale: CGFloat {
        switch pongFieldSizeLevel {
        case 1: return 0.52
        case 2: return 0.68
        case 3: return 0.84
        default: return 1.0
        }
    }

    var pongView: some View {
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

                Text("↑/↓ o rueda mueve · → start · ← reset")
                    .font(.system(size: max(11, height * 0.043), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { startPong() },
                    onRightClick: { resetPongGame() },
                    onScroll: { deltaY in
                        movePongPaddleWithScroll(deltaY)
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

    func activatePongMode() {
        installPongKeyboardMonitorsIfNeeded()
        startPongLoopIfNeeded()
    }

    func deactivatePongMode() {
        pongUpPressed = false
        pongDownPressed = false
        pongTimer?.setEventHandler {}
        pongTimer?.cancel()
        pongTimer = nil
        removePongKeyboardMonitors()
    }

    func startPongLoopIfNeeded() {
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

    func installPongKeyboardMonitorsIfNeeded() {
        if pongKeyboardMonitor == nil {
            pongKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isGameActive(.pong) else { return event }
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
                guard isGameActive(.pong) else { return event }
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

    func removePongKeyboardMonitors() {
        if let monitor = pongKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            pongKeyboardMonitor = nil
        }
        if let monitor = pongKeyboardFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            pongKeyboardFlagsMonitor = nil
        }
    }

    func startPong() {
        pongRunning = true
    }

    func movePongPaddleWithScroll(_ deltaY: CGFloat) {
        guard isGameActive(.pong) else { return }
        let sensitivity: CGFloat = 0.0015
        let paddleHalfHeight: CGFloat = 0.11
        let nextTarget = pongPlayerPaddleTargetY - (deltaY * sensitivity)
        pongPlayerPaddleTargetY = max(paddleHalfHeight, min(1 - paddleHalfHeight, nextTarget))
    }

    func resetPongGame() {
        pongRunning = false
        pongPlayerScore = 0
        pongCPUScore = 0
        pongPlayerPaddleCenterY = 0.5
        pongPlayerPaddleTargetY = 0.5
        pongAIPaddleCenterY = 0.5
        resetPongServe(towardsRight: Bool.random())
    }

    func resetPongServe(towardsRight: Bool) {
        let horizontalDirection: CGFloat = towardsRight ? 1 : -1
        let randomY = CGFloat.random(in: -0.22...0.22)
        pongBallPosition = CGPoint(x: 0.5, y: 0.5)
        pongBallVelocity = CGVector(dx: 0.62 * horizontalDirection, dy: randomY)
    }

    func updatePongFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.pong) else { return }
        let paddleSpeed: CGFloat = 0.95
        let aiPaddleSpeed: CGFloat = 0.46
        let paddleHalfHeight: CGFloat = 0.11
        let paddleX: CGFloat = 0.055
        let rightPaddleX: CGFloat = 1 - paddleX
        let paddleWidth: CGFloat = 0.018
        let ballRadius: CGFloat = 0.02

        if pongUpPressed {
            pongPlayerPaddleCenterY -= paddleSpeed * dt
            pongPlayerPaddleTargetY = pongPlayerPaddleCenterY
        }
        if pongDownPressed {
            pongPlayerPaddleCenterY += paddleSpeed * dt
            pongPlayerPaddleTargetY = pongPlayerPaddleCenterY
        }
        if pongUpPressed == false, pongDownPressed == false {
            let smoothing = min(1, dt * 16)
            pongPlayerPaddleCenterY += (pongPlayerPaddleTargetY - pongPlayerPaddleCenterY) * smoothing
        }
        pongPlayerPaddleCenterY = max(paddleHalfHeight, min(1 - paddleHalfHeight, pongPlayerPaddleCenterY))
        pongPlayerPaddleTargetY = max(paddleHalfHeight, min(1 - paddleHalfHeight, pongPlayerPaddleTargetY))

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

    var arkanoidColumns: Int { 8 }
    var arkanoidRows: Int { 5 }

    var arkanoidView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height
            let paddleBoostRatio: CGFloat = arkanoidPaddleBoostRemaining > 0 ? 1.35 : 1.0
            let paddleWidth = width * 0.2 * paddleBoostRatio
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
                    Text("ARKANOID PRO  \(arkanoidScore)")
                        .font(displayFont(size: max(20, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text("LIVES \(arkanoidLives) · \(arkanoidRunning ? "RUN" : "STOP")\(arkanoidPaddleBoostRemaining > 0 ? " · BOOST" : "")")
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

    func activateArkanoidMode() {
        if arkanoidBrickAlive.count != arkanoidRows * arkanoidColumns {
            arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
        }
        installArkanoidKeyboardMonitorsIfNeeded()
        startArkanoidLoopIfNeeded()
    }

    func deactivateArkanoidMode() {
        arkanoidLeftPressed = false
        arkanoidRightPressed = false
        arkanoidTimer?.setEventHandler {}
        arkanoidTimer?.cancel()
        arkanoidTimer = nil
        removeArkanoidKeyboardMonitors()
    }

    func startArkanoidLoopIfNeeded() {
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

    func installArkanoidKeyboardMonitorsIfNeeded() {
        if arkanoidKeyboardMonitor == nil {
            arkanoidKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isGameActive(.arkanoid) else { return event }
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
                guard isGameActive(.arkanoid) else { return event }
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

    func removeArkanoidKeyboardMonitors() {
        if let monitor = arkanoidKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            arkanoidKeyboardMonitor = nil
        }
        if let monitor = arkanoidKeyboardFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            arkanoidKeyboardFlagsMonitor = nil
        }
    }

    func startArkanoid() {
        arkanoidRunning = true
    }

    func resetArkanoidGame() {
        arkanoidRunning = false
        arkanoidScore = 0
        arkanoidLives = 3
        arkanoidPaddleBoostRemaining = 0
        arkanoidHitsSinceBoost = 0
        arkanoidPaddleCenterX = 0.5
        arkanoidBrickAlive = Array(repeating: true, count: arkanoidRows * arkanoidColumns)
        resetArkanoidServe()
    }

    func resetArkanoidServe() {
        let randomDX = CGFloat.random(in: -0.32...0.32)
        arkanoidBallPosition = CGPoint(x: arkanoidPaddleCenterX, y: 0.78)
        arkanoidBallVelocity = CGVector(dx: randomDX, dy: -0.62)
    }

    func arkanoidBrickRect(index: Int) -> CGRect {
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

    func updateArkanoidFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.arkanoid) else { return }
        let paddleSpeed: CGFloat = 1.0
        if arkanoidPaddleBoostRemaining > 0 {
            arkanoidPaddleBoostRemaining = max(0, arkanoidPaddleBoostRemaining - dt)
        }
        let paddleHalfWidth: CGFloat = 0.1 * (arkanoidPaddleBoostRemaining > 0 ? 1.35 : 1.0)
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
                arkanoidHitsSinceBoost += 1
                if arkanoidHitsSinceBoost >= 6 {
                    arkanoidPaddleBoostRemaining = 7.5
                    arkanoidHitsSinceBoost = 0
                }
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

    var missileCommandView: some View {
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

    func activateMissileCommandMode() {
        if missileCities.count != 6 || missileBases.count != 3 {
            resetMissileCommandGame()
        }
        startMissileCommandLoopIfNeeded()
    }

    func deactivateMissileCommandMode() {
        missileTimer?.setEventHandler {}
        missileTimer?.cancel()
        missileTimer = nil
    }

    func startMissileCommandLoopIfNeeded() {
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

    func resetMissileCommandGame() {
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

    func missileCommandFire(at point: CGPoint) {
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

    func updateMissileCommandFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.missileCommand) else { return }
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

    func spawnMissileEnemy() {
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

    func normalizeMissileInput(_ point: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        let normalizedX = max(0, min(1, point.x / max(1, width)))
        // NSEvent reports Y from bottom-left; game coordinates are top-left.
        let normalizedYTop = 1 - (point.y / max(1, height))
        return CGPoint(
            x: normalizedX,
            y: max(0.05, min(0.92, normalizedYTop))
        )
    }

    func nearestAliveMissileBase(to point: CGPoint) -> Int? {
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

    func randomMissileTarget() -> (point: CGPoint, kind: MissileTargetKind)? {
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

    func missileExplosionRadius(_ explosion: MissileExplosion) -> CGFloat {
        let progress = max(0, min(1, explosion.age / max(0.0001, explosion.maxAge)))
        if progress < 0.5 {
            return explosion.maxRadius * (progress / 0.5)
        }
        return explosion.maxRadius * ((1 - progress) / 0.5)
    }

    func missileCityPosition(index: Int) -> CGPoint {
        let x = 0.12 + CGFloat(index) * 0.15
        return CGPoint(x: x, y: 0.9)
    }

    func missileBasePosition(index: Int) -> CGPoint {
        let values: [CGFloat] = [0.16, 0.5, 0.84]
        let safe = min(max(index, 0), values.count - 1)
        return CGPoint(x: values[safe], y: 0.935)
    }

    var snakeCols: Int32 {
        switch snakeBoardSizeLevel {
        case 1: return 12
        case 2: return 18
        case 3: return 28
        default: return 40
        }
    }

    var snakeRows: Int32 {
        switch snakeBoardSizeLevel {
        case 1: return 8
        case 2: return 11
        case 3: return 16
        default: return 24
        }
    }

    var snakeBoardWidthScale: CGFloat {
        switch snakeBoardSizeLevel {
        case 1: return 0.64
        case 2: return 0.76
        case 3: return 0.88
        default: return 0.98
        }
    }

    var snakeBoardHeightScale: CGFloat {
        switch snakeBoardSizeLevel {
        case 1: return 0.52
        case 2: return 0.62
        case 3: return 0.74
        default: return 0.86
        }
    }

    var snakeView: some View {
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

    func activateSnakeMode() {
        if snakeBody.isEmpty {
            resetSnakeGame()
        }
        installSnakeKeyboardMonitorIfNeeded()
        startSnakeLoopIfNeeded()
    }

    func deactivateSnakeMode() {
        snakeTimer?.setEventHandler {}
        snakeTimer?.cancel()
        snakeTimer = nil
        if let monitor = snakeKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            snakeKeyboardMonitor = nil
        }
    }

    func startSnakeLoopIfNeeded() {
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

    func installSnakeKeyboardMonitorIfNeeded() {
        guard snakeKeyboardMonitor == nil else { return }
        snakeKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.snake) else { return event }
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

    func queueSnakeDirection(_ direction: CGVector) {
        if snakeDirection.dx + direction.dx == 0, snakeDirection.dy + direction.dy == 0 {
            return
        }
        snakePendingDirection = direction
    }

    func resetSnakeGame() {
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

    func placeSnakeFood() {
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

    func updateSnakeFrame(currentTime now: TimeInterval) {
        guard isGameActive(.snake) else { return }
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

    func advanceSnakeOneStep() {
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

    var chromeDinoView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height
            let groundY = height * 0.84
            let dinoX = width * 0.18
            let dinoWidth = width * 0.062
            let dinoHeight = height * 0.17
            let dinoBottom = groundY - (chromeDinoJumpHeight * height)
            let dinoDrawRect = CGRect(
                x: dinoX - (dinoWidth * 0.5),
                y: dinoBottom - dinoHeight,
                width: dinoWidth,
                height: dinoHeight
            )
            let runFrame = (chromeDinoRunning && chromeDinoJumpHeight <= 0.001)
                ? Int((viewModel.now.timeIntervalSinceReferenceDate * 22).truncatingRemainder(dividingBy: 4))
                : 1
            let shoulderY = dinoDrawRect.minY + (dinoDrawRect.height * 0.35)
            let hipY = dinoDrawRect.minY + (dinoDrawRect.height * 0.62)
            let lineWidth = max(2, dinoDrawRect.width * 0.10)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                Rectangle()
                    .fill(phosphorColor.opacity(0.34))
                    .frame(height: 2)
                    .position(x: width * 0.5, y: groundY)

                ForEach(chromeDinoObstacles) { obstacle in
                    let obstacleWidth = width * obstacle.width
                    let obstacleHeight = height * obstacle.height
                    let obstacleX = width * obstacle.x
                    let obstacleCenterY = groundY - (height * obstacle.groundOffset) - (obstacleHeight * 0.5)
                    switch obstacle.kind {
                    case .bird:
                        let flap = sin((viewModel.now.timeIntervalSinceReferenceDate * 12) + Double(obstacleX * 0.06))
                        let wingLift = CGFloat(flap) * obstacleHeight * 0.18
                        ZStack {
                            Ellipse()
                                .fill(phosphorColor.opacity(0.92))
                                .frame(width: obstacleWidth * 0.44, height: obstacleHeight * 0.32)

                            Path { path in
                                let wingY = -obstacleHeight * 0.06
                                path.move(to: CGPoint(x: -obstacleWidth * 0.16, y: wingY))
                                path.addLine(to: CGPoint(x: -obstacleWidth * 0.44, y: wingY - wingLift))
                                path.move(to: CGPoint(x: obstacleWidth * 0.10, y: wingY))
                                path.addLine(to: CGPoint(x: obstacleWidth * 0.38, y: wingY - wingLift))
                            }
                            .stroke(phosphorColor.opacity(0.95), style: StrokeStyle(lineWidth: max(2, obstacleHeight * 0.14), lineCap: .round))

                            Path { path in
                                path.move(to: CGPoint(x: obstacleWidth * 0.24, y: 0))
                                path.addLine(to: CGPoint(x: obstacleWidth * 0.36, y: -obstacleHeight * 0.05))
                                path.addLine(to: CGPoint(x: obstacleWidth * 0.36, y: obstacleHeight * 0.05))
                                path.closeSubpath()
                            }
                            .fill(phosphorColor.opacity(0.88))
                        }
                        .position(x: obstacleX, y: obstacleCenterY)
                    case .stone:
                        Path { path in
                            let left = obstacleX - (obstacleWidth * 0.5)
                            let right = obstacleX + (obstacleWidth * 0.5)
                            let top = obstacleCenterY - (obstacleHeight * 0.5)
                            let bottom = obstacleCenterY + (obstacleHeight * 0.5)
                            path.move(to: CGPoint(x: left + obstacleWidth * 0.08, y: bottom))
                            path.addLine(to: CGPoint(x: left, y: bottom - obstacleHeight * 0.24))
                            path.addLine(to: CGPoint(x: left + obstacleWidth * 0.20, y: top + obstacleHeight * 0.08))
                            path.addLine(to: CGPoint(x: right - obstacleWidth * 0.24, y: top))
                            path.addLine(to: CGPoint(x: right, y: bottom - obstacleHeight * 0.20))
                            path.addLine(to: CGPoint(x: right - obstacleWidth * 0.10, y: bottom))
                            path.closeSubpath()
                        }
                        .fill(phosphorColor.opacity(0.92))
                    case .tree:
                        ZStack {
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(phosphorColor.opacity(0.78))
                                .frame(width: obstacleWidth * 0.24, height: obstacleHeight * 0.44)
                                .offset(y: obstacleHeight * 0.22)

                            Circle()
                                .fill(phosphorColor.opacity(0.94))
                                .frame(width: obstacleWidth * 0.48, height: obstacleHeight * 0.38)
                                .offset(x: -obstacleWidth * 0.14, y: -obstacleHeight * 0.10)
                            Circle()
                                .fill(phosphorColor.opacity(0.94))
                                .frame(width: obstacleWidth * 0.54, height: obstacleHeight * 0.44)
                                .offset(y: -obstacleHeight * 0.18)
                            Circle()
                                .fill(phosphorColor.opacity(0.94))
                                .frame(width: obstacleWidth * 0.46, height: obstacleHeight * 0.36)
                                .offset(x: obstacleWidth * 0.15, y: -obstacleHeight * 0.08)
                        }
                        .position(x: obstacleX, y: obstacleCenterY)
                    }
                }

                // Side-profile stickman with 4 keyframes based on the provided reference.
                let headRadius = dinoDrawRect.height * 0.095
                let headCenter = CGPoint(
                    x: dinoDrawRect.midX + dinoDrawRect.width * 0.10,
                    y: dinoDrawRect.minY + headRadius + dinoDrawRect.height * 0.015
                )
                let torsoTop = CGPoint(x: headCenter.x - dinoDrawRect.width * 0.08, y: shoulderY)
                let hipPoint = CGPoint(x: torsoTop.x + dinoDrawRect.width * 0.03, y: hipY)

                Circle()
                    .stroke(phosphorColor, lineWidth: lineWidth * 0.78)
                    .frame(width: headRadius * 2, height: headRadius * 2)
                    .position(x: headCenter.x, y: headCenter.y)
                Circle()
                    .fill(phosphorColor.opacity(0.92))
                    .frame(width: max(1.8, headRadius * 0.32), height: max(1.8, headRadius * 0.32))
                    .position(x: headCenter.x + headRadius * 0.34, y: headCenter.y - headRadius * 0.06)

                Path { path in
                    // Slight forward lean on torso reinforces "running".
                    path.move(to: torsoTop)
                    path.addLine(to: hipPoint)
                }
                .stroke(phosphorColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                let rearArmElbowOffsets = [
                    CGPoint(x: -0.11, y: 0.10),
                    CGPoint(x: -0.08, y: 0.03),
                    CGPoint(x: -0.04, y: -0.06),
                    CGPoint(x: -0.09, y: 0.02)
                ]
                let rearArmHandOffsets = [
                    CGPoint(x: -0.22, y: 0.20),
                    CGPoint(x: -0.16, y: 0.12),
                    CGPoint(x: -0.02, y: -0.15),
                    CGPoint(x: -0.14, y: 0.09)
                ]
                let frontArmElbowOffsets = [
                    CGPoint(x: 0.08, y: -0.04),
                    CGPoint(x: 0.14, y: -0.11),
                    CGPoint(x: 0.17, y: -0.03),
                    CGPoint(x: 0.10, y: 0.07)
                ]
                let frontArmHandOffsets = [
                    CGPoint(x: 0.21, y: -0.12),
                    CGPoint(x: 0.24, y: -0.19),
                    CGPoint(x: 0.26, y: 0.06),
                    CGPoint(x: 0.22, y: 0.15)
                ]
                let rearLegKneeOffsets = [
                    CGPoint(x: -0.04, y: 0.17),
                    CGPoint(x: -0.09, y: 0.23),
                    CGPoint(x: -0.13, y: 0.28),
                    CGPoint(x: -0.10, y: 0.22)
                ]
                let rearLegFootOffsets = [
                    CGPoint(x: -0.18, y: 0.31),
                    CGPoint(x: -0.24, y: 0.36),
                    CGPoint(x: -0.28, y: 0.41),
                    CGPoint(x: -0.23, y: 0.37)
                ]
                let frontLegKneeOffsets = [
                    CGPoint(x: 0.10, y: 0.10),
                    CGPoint(x: 0.14, y: 0.15),
                    CGPoint(x: 0.08, y: 0.20),
                    CGPoint(x: 0.03, y: 0.17)
                ]
                let frontLegFootOffsets = [
                    CGPoint(x: 0.24, y: 0.20),
                    CGPoint(x: 0.28, y: 0.27),
                    CGPoint(x: 0.19, y: 0.35),
                    CGPoint(x: 0.11, y: 0.34)
                ]

                let pointFrom: (CGPoint, CGPoint) -> CGPoint = { origin, offset in
                    CGPoint(
                        x: origin.x + (offset.x * dinoDrawRect.width),
                        y: origin.y + (offset.y * dinoDrawRect.height)
                    )
                }

                let rearElbow = pointFrom(torsoTop, rearArmElbowOffsets[runFrame])
                let rearHand = pointFrom(torsoTop, rearArmHandOffsets[runFrame])
                Path { path in
                    path.move(to: torsoTop)
                    path.addLine(to: rearElbow)
                    path.addLine(to: rearHand)
                }
                .stroke(phosphorColor.opacity(0.72), style: StrokeStyle(lineWidth: lineWidth * 0.86, lineCap: .round))

                let frontElbow = pointFrom(torsoTop, frontArmElbowOffsets[runFrame])
                let frontHand = pointFrom(torsoTop, frontArmHandOffsets[runFrame])
                Path { path in
                    path.move(to: torsoTop)
                    path.addLine(to: frontElbow)
                    path.addLine(to: frontHand)
                }
                .stroke(phosphorColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                let rearKnee = pointFrom(hipPoint, rearLegKneeOffsets[runFrame])
                let rearFoot = pointFrom(hipPoint, rearLegFootOffsets[runFrame])
                Path { path in
                    path.move(to: hipPoint)
                    path.addLine(to: rearKnee)
                    path.addLine(to: rearFoot)
                }
                .stroke(phosphorColor.opacity(0.74), style: StrokeStyle(lineWidth: lineWidth * 0.9, lineCap: .round))

                let frontKnee = pointFrom(hipPoint, frontLegKneeOffsets[runFrame])
                let frontFoot = pointFrom(hipPoint, frontLegFootOffsets[runFrame])
                Path { path in
                    path.move(to: hipPoint)
                    path.addLine(to: frontKnee)
                    path.addLine(to: frontFoot)
                }
                .stroke(phosphorColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                VStack(spacing: 4) {
                    Text("JUMP N' RUN  \(Int(chromeDinoScore))")
                        .font(displayFont(size: max(20, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(chromeDinoGameOver ? "GAME OVER" : (chromeDinoRunning ? "RUN" : "READY"))
                        .font(.system(size: max(12, height * 0.045), weight: .regular, design: .monospaced))
                        .foregroundStyle(chromeDinoGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("espacio o click derecho: saltar · click izq: pausa")
                    .font(.system(size: max(11, height * 0.041), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 9)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: {
                        chromeDinoRunning.toggle()
                    },
                    onRightClick: {
                        chromeDinoJump()
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

    func activateChromeDinoMode() {
        if chromeDinoObstacles.isEmpty && chromeDinoScore == 0 && chromeDinoJumpHeight == 0 {
            resetChromeDinoGame(startRunning: false)
        }
        installChromeDinoKeyboardMonitorIfNeeded()
        startChromeDinoLoopIfNeeded()
    }

    func deactivateChromeDinoMode() {
        chromeDinoTimer?.setEventHandler {}
        chromeDinoTimer?.cancel()
        chromeDinoTimer = nil
        if let monitor = chromeDinoKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            chromeDinoKeyboardMonitor = nil
        }
    }

    func installChromeDinoKeyboardMonitorIfNeeded() {
        guard chromeDinoKeyboardMonitor == nil else { return }
        chromeDinoKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.chromeDino) else { return event }
            switch event.keyCode {
            case 49: // space
                chromeDinoJump()
                return nil
            case 53: // esc
                resetChromeDinoGame(startRunning: false)
                return nil
            default:
                return event
            }
        }
    }

    func startChromeDinoLoopIfNeeded() {
        guard chromeDinoTimer == nil else { return }
        var lastTick = CACurrentMediaTime()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            let now = CACurrentMediaTime()
            let delta = max(1.0 / 240.0, min(1.0 / 20.0, now - lastTick))
            lastTick = now
            DispatchQueue.main.async {
                updateChromeDinoFrame(deltaTime: CGFloat(delta))
            }
        }
        timer.resume()
        chromeDinoTimer = timer
    }

    func resetChromeDinoGame(startRunning: Bool) {
        chromeDinoRunning = startRunning
        chromeDinoGameOver = false
        chromeDinoScore = 0
        chromeDinoJumpHeight = 0
        chromeDinoJumpVelocity = 0
        chromeDinoSpeed = 0.66
        chromeDinoSpawnAccumulator = 0.25
        chromeDinoObstacles = []
    }

    func chromeDinoJump() {
        if chromeDinoGameOver {
            resetChromeDinoGame(startRunning: true)
            return
        }
        if chromeDinoRunning == false {
            chromeDinoRunning = true
        }
        if chromeDinoJumpHeight <= 0.001 {
            chromeDinoJumpVelocity = 1.62
        }
    }

    func updateChromeDinoFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.chromeDino) else { return }

        let gravity: CGFloat = 6.2
        chromeDinoJumpVelocity -= gravity * dt
        chromeDinoJumpHeight += chromeDinoJumpVelocity * dt
        if chromeDinoJumpHeight < 0 {
            chromeDinoJumpHeight = 0
            chromeDinoJumpVelocity = 0
        }

        guard chromeDinoRunning, chromeDinoGameOver == false else { return }

        chromeDinoScore += Double(dt * 145)
        chromeDinoSpeed = min(1.06, chromeDinoSpeed + (dt * 0.024))
        chromeDinoSpawnAccumulator -= dt
        if chromeDinoSpawnAccumulator <= 0 {
            spawnChromeDinoObstacle()
            let baseGap = max(0.34, 0.96 - (chromeDinoSpeed * 0.32))
            chromeDinoSpawnAccumulator = CGFloat.random(in: baseGap...(baseGap + 0.45))
        }

        for index in chromeDinoObstacles.indices {
            chromeDinoObstacles[index].x -= chromeDinoSpeed * dt
        }
        chromeDinoObstacles.removeAll { $0.x < -0.2 }

        if chromeDinoHasCollision() {
            chromeDinoRunning = false
            chromeDinoGameOver = true
            triggerFlash()
        }
    }

    func spawnChromeDinoObstacle() {
        let roll = CGFloat.random(in: 0...1)
        let kind: DinoObstacleKind
        if roll < 0.22 {
            kind = .bird
        } else if roll < 0.60 {
            kind = .stone
        } else {
            kind = .tree
        }

        switch kind {
        case .stone:
            chromeDinoObstacles.append(
                DinoObstacle(
                    kind: .stone,
                    x: 1.08,
                    width: CGFloat.random(in: 0.026...0.038),
                    height: CGFloat.random(in: 0.050...0.076),
                    groundOffset: 0
                )
            )
        case .tree:
            chromeDinoObstacles.append(
                DinoObstacle(
                    kind: .tree,
                    x: 1.08,
                    width: CGFloat.random(in: 0.034...0.052),
                    height: CGFloat.random(in: 0.120...0.170),
                    groundOffset: 0
                )
            )
        case .bird:
            chromeDinoObstacles.append(
                DinoObstacle(
                    kind: .bird,
                    x: 1.08,
                    width: CGFloat.random(in: 0.046...0.064),
                    height: CGFloat.random(in: 0.048...0.070),
                    groundOffset: CGFloat.random(in: 0.135...0.225)
                )
            )
        }
    }

    func chromeDinoHasCollision() -> Bool {
        let dinoX: CGFloat = 0.18
        let dinoWidth: CGFloat = 0.062
        let dinoHeight: CGFloat = 0.17
        let groundY: CGFloat = 0.84
        let dinoBottom = groundY - chromeDinoJumpHeight
        let dinoRect = CGRect(
            x: dinoX - (dinoWidth * 0.28),
            y: dinoBottom - (dinoHeight * 0.86),
            width: dinoWidth * 0.56,
            height: dinoHeight * 0.86
        )

        for obstacle in chromeDinoObstacles {
            let obstacleY = groundY - obstacle.groundOffset
            let obstacleRect = CGRect(
                x: obstacle.x - (obstacle.width * 0.5),
                y: obstacleY - obstacle.height,
                width: obstacle.width,
                height: obstacle.height
            )
            if dinoRect.intersects(obstacleRect) {
                return true
            }
        }
        return false
    }

    var tetrisRows: Int { 20 }
    var tetrisCols: Int { 10 }

    var tetrisView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let targetBoardHeight = height * 0.88
            let targetBoardWidth = min(width * 0.62, targetBoardHeight * 0.5)
            let cellSize = min(targetBoardWidth / CGFloat(tetrisCols), targetBoardHeight / CGFloat(tetrisRows))
            let boardWidth = cellSize * CGFloat(tetrisCols)
            let boardHeight = cellSize * CGFloat(tetrisRows)
            let boardX = (width - boardWidth) * 0.5
            let boardY = (height - boardHeight) * 0.5

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.38))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(phosphorColor.opacity(0.28), lineWidth: 1)
                    )
                    .frame(width: boardWidth + 8, height: boardHeight + 8)
                    .position(x: boardX + (boardWidth * 0.5), y: boardY + (boardHeight * 0.5))

                ForEach(0..<tetrisRows, id: \.self) { row in
                    ForEach(0..<tetrisCols, id: \.self) { col in
                        if row < tetrisBoard.count, col < tetrisBoard[row].count, tetrisBoard[row][col] > 0 {
                            RoundedRectangle(cornerRadius: max(2, cellSize * 0.12), style: .continuous)
                                .fill(phosphorColor.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(2, cellSize * 0.12), style: .continuous)
                                        .stroke(phosphorColor.opacity(0.95), lineWidth: max(1, cellSize * 0.06))
                                )
                                .frame(width: cellSize - 1, height: cellSize - 1)
                                .position(
                                    x: boardX + (CGFloat(col) + 0.5) * cellSize,
                                    y: boardY + (CGFloat(row) + 0.5) * cellSize
                                )
                        }
                    }
                }

                if let piece = tetrisCurrentPiece {
                    ForEach(Array(tetrisCells(for: piece).enumerated()), id: \.offset) { _, cell in
                        if cell.y >= 0 {
                            RoundedRectangle(cornerRadius: max(2, cellSize * 0.12), style: .continuous)
                                .fill(phosphorColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: max(2, cellSize * 0.12), style: .continuous)
                                        .stroke(Color.white.opacity(0.75), lineWidth: max(1, cellSize * 0.08))
                                )
                                .frame(width: cellSize - 1, height: cellSize - 1)
                                .position(
                                    x: boardX + (CGFloat(cell.x) + 0.5) * cellSize,
                                    y: boardY + (CGFloat(cell.y) + 0.5) * cellSize
                                )
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text("TETRIS  \(tetrisScore)")
                        .font(displayFont(size: max(20, height * 0.09), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(tetrisGameOver ? "GAME OVER" : (tetrisRunning ? "RUN · LV \(tetrisLevel)" : "READY · LV \(tetrisLevel)"))
                        .font(.system(size: max(11, height * 0.05), weight: .regular, design: .monospaced))
                        .foregroundStyle(tetrisGameOver ? Color.red : phosphorDim)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("←/→ mover · ↑ rotar · ↓ bajar · espacio drop · enter start")
                    .font(.system(size: max(10, height * 0.040), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { tetrisRunning.toggle() },
                    onRightClick: { resetTetrisGame() }
                )
            )
        }
    }

    func activateTetrisMode() {
        if tetrisCurrentPiece == nil, tetrisScore == 0 {
            resetTetrisGame(startRunning: false)
        }
        installTetrisKeyboardMonitorIfNeeded()
        startTetrisTimerIfNeeded()
    }

    func deactivateTetrisMode() {
        tetrisTimer?.setEventHandler {}
        tetrisTimer?.cancel()
        tetrisTimer = nil
        if let monitor = tetrisKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            tetrisKeyboardMonitor = nil
        }
        if let monitor = tetrisKeyboardUpMonitor {
            NSEvent.removeMonitor(monitor)
            tetrisKeyboardUpMonitor = nil
        }
        tetrisSoftDropPressed = false
    }

    func installTetrisKeyboardMonitorIfNeeded() {
        if tetrisKeyboardMonitor == nil {
            tetrisKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isGameActive(.tetris) else { return event }
                switch event.keyCode {
                case 123:
                    tetrisMoveCurrentPiece(dx: -1)
                    return nil
                case 124:
                    tetrisMoveCurrentPiece(dx: 1)
                    return nil
                case 125:
                    tetrisSoftDropPressed = true
                    return nil
                case 126:
                    tetrisRotateCurrentPiece()
                    return nil
                case 36:
                    tetrisRunning.toggle()
                    return nil
                case 49:
                    tetrisHardDrop()
                    return nil
                case 15:
                    resetTetrisGame()
                    return nil
                default:
                    return event
                }
            }
        }

        if tetrisKeyboardUpMonitor == nil {
            tetrisKeyboardUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
                guard isGameActive(.tetris) else { return event }
                if event.keyCode == 125 {
                    tetrisSoftDropPressed = false
                    return nil
                }
                return event
            }
        }
    }

    func startTetrisTimerIfNeeded() {
        guard tetrisTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            updateTetrisFrame(deltaTime: CGFloat(Double(gameLoopIntervalMs) / 1000))
        }
        timer.resume()
        tetrisTimer = timer
    }

    func resetTetrisGame(startRunning: Bool = false) {
        tetrisRunning = startRunning
        tetrisGameOver = false
        tetrisScore = 0
        tetrisLevel = 1
        tetrisSoftDropPressed = false
        tetrisDropAccumulator = 0
        tetrisBoard = Array(repeating: Array(repeating: 0, count: tetrisCols), count: tetrisRows)
        tetrisCurrentPiece = nil
        tetrisSpawnPiece()
    }

    func updateTetrisFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.tetris) else { return }
        guard tetrisGameOver == false else { return }
        guard tetrisRunning else { return }

        if tetrisCurrentPiece == nil {
            tetrisSpawnPiece()
        }

        let baseFallInterval = max(0.09, 0.62 - (CGFloat(tetrisLevel - 1) * 0.048))
        let fallInterval = tetrisSoftDropPressed ? max(0.02, baseFallInterval * 0.18) : baseFallInterval
        tetrisDropAccumulator += dt
        var safety = 0
        while tetrisDropAccumulator >= fallInterval, safety < 5 {
            tetrisDropAccumulator -= fallInterval
            safety += 1
            tetrisSoftDrop()
            if tetrisGameOver {
                break
            }
        }
    }

    func tetrisSpawnPiece() {
        let kind = TetrisPieceKind.allCases.randomElement() ?? .t
        let piece = TetrisPieceState(kind: kind, rotation: 0, x: 4, y: 0)
        if tetrisIsValidPosition(piece) {
            tetrisCurrentPiece = piece
        } else {
            tetrisRunning = false
            tetrisGameOver = true
            triggerFlash()
        }
    }

    func tetrisMoveCurrentPiece(dx: Int) {
        guard var piece = tetrisCurrentPiece else { return }
        piece.x += dx
        if tetrisIsValidPosition(piece) {
            tetrisCurrentPiece = piece
        }
    }

    func tetrisRotateCurrentPiece() {
        guard var piece = tetrisCurrentPiece else { return }
        let original = piece
        piece.rotation = (piece.rotation + 1) % 4
        if tetrisIsValidPosition(piece) {
            tetrisCurrentPiece = piece
            return
        }
        for offset in [-1, 1, -2, 2] {
            var shifted = piece
            shifted.x += offset
            if tetrisIsValidPosition(shifted) {
                tetrisCurrentPiece = shifted
                return
            }
        }
        tetrisCurrentPiece = original
    }

    func tetrisSoftDrop() {
        guard var piece = tetrisCurrentPiece else { return }
        piece.y += 1
        if tetrisIsValidPosition(piece) {
            tetrisCurrentPiece = piece
            return
        }
        tetrisLockCurrentPiece()
    }

    func tetrisHardDrop() {
        guard var piece = tetrisCurrentPiece else { return }
        while true {
            var next = piece
            next.y += 1
            if tetrisIsValidPosition(next) {
                piece = next
            } else {
                break
            }
        }
        tetrisCurrentPiece = piece
        tetrisLockCurrentPiece()
    }

    func tetrisLockCurrentPiece() {
        guard let piece = tetrisCurrentPiece else { return }
        for cell in tetrisCells(for: piece) where cell.y >= 0 && cell.y < tetrisRows && cell.x >= 0 && cell.x < tetrisCols {
            tetrisBoard[cell.y][cell.x] = 1
        }
        tetrisCurrentPiece = nil
        let cleared = tetrisClearFilledLines()
        if cleared > 0 {
            let points: Int
            switch cleared {
            case 1: points = 100
            case 2: points = 300
            case 3: points = 500
            default: points = 800
            }
            tetrisScore += points * tetrisLevel
            tetrisLevel = min(20, 1 + (tetrisScore / 600))
            triggerFlash()
        }
        tetrisSpawnPiece()
    }

    func tetrisClearFilledLines() -> Int {
        var keptRows = tetrisBoard.filter { row in
            row.contains(0)
        }
        let removed = tetrisRows - keptRows.count
        if removed > 0 {
            for _ in 0..<removed {
                keptRows.insert(Array(repeating: 0, count: tetrisCols), at: 0)
            }
            tetrisBoard = keptRows
        }
        return removed
    }

    func tetrisIsValidPosition(_ piece: TetrisPieceState) -> Bool {
        for cell in tetrisCells(for: piece) {
            if cell.x < 0 || cell.x >= tetrisCols || cell.y >= tetrisRows {
                return false
            }
            if cell.y >= 0, tetrisBoard[cell.y][cell.x] != 0 {
                return false
            }
        }
        return true
    }

    func tetrisCells(for piece: TetrisPieceState) -> [SIMD2<Int>] {
        let shape = tetrisShape(kind: piece.kind, rotation: piece.rotation)
        return shape.map { offset in
            SIMD2<Int>(piece.x + offset.x, piece.y + offset.y)
        }
    }

    func tetrisShape(kind: TetrisPieceKind, rotation: Int) -> [SIMD2<Int>] {
        let r = ((rotation % 4) + 4) % 4
        switch kind {
        case .i:
            switch r {
            case 1, 3: return [SIMD2(1, 0), SIMD2(1, 1), SIMD2(1, 2), SIMD2(1, 3)]
            default: return [SIMD2(0, 1), SIMD2(1, 1), SIMD2(2, 1), SIMD2(3, 1)]
            }
        case .o:
            return [SIMD2(1, 0), SIMD2(2, 0), SIMD2(1, 1), SIMD2(2, 1)]
        case .t:
            switch r {
            case 1: return [SIMD2(1, 0), SIMD2(1, 1), SIMD2(2, 1), SIMD2(1, 2)]
            case 2: return [SIMD2(0, 1), SIMD2(1, 1), SIMD2(2, 1), SIMD2(1, 2)]
            case 3: return [SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1), SIMD2(1, 2)]
            default: return [SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1), SIMD2(2, 1)]
            }
        case .s:
            switch r {
            case 1, 3: return [SIMD2(1, 0), SIMD2(1, 1), SIMD2(2, 1), SIMD2(2, 2)]
            default: return [SIMD2(1, 1), SIMD2(2, 1), SIMD2(0, 2), SIMD2(1, 2)]
            }
        case .z:
            switch r {
            case 1, 3: return [SIMD2(2, 0), SIMD2(1, 1), SIMD2(2, 1), SIMD2(1, 2)]
            default: return [SIMD2(0, 1), SIMD2(1, 1), SIMD2(1, 2), SIMD2(2, 2)]
            }
        case .j:
            switch r {
            case 1: return [SIMD2(1, 0), SIMD2(2, 0), SIMD2(1, 1), SIMD2(1, 2)]
            case 2: return [SIMD2(0, 1), SIMD2(1, 1), SIMD2(2, 1), SIMD2(2, 2)]
            case 3: return [SIMD2(1, 0), SIMD2(1, 1), SIMD2(0, 2), SIMD2(1, 2)]
            default: return [SIMD2(0, 1), SIMD2(0, 2), SIMD2(1, 2), SIMD2(2, 2)]
            }
        case .l:
            switch r {
            case 1: return [SIMD2(1, 0), SIMD2(1, 1), SIMD2(1, 2), SIMD2(2, 2)]
            case 2: return [SIMD2(0, 1), SIMD2(1, 1), SIMD2(2, 1), SIMD2(0, 2)]
            case 3: return [SIMD2(0, 0), SIMD2(1, 0), SIMD2(1, 1), SIMD2(1, 2)]
            default: return [SIMD2(2, 1), SIMD2(0, 2), SIMD2(1, 2), SIMD2(2, 2)]
            }
        }
    }

    var spaceInvadersView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.94
            let height = geometry.size.height
            let playerY = height * 0.90

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(spaceInvadersEnemies) { enemy in
                    let x = width * enemy.x
                    let y = height * enemy.y
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(phosphorColor.opacity(0.92))
                            .frame(width: width * 0.045, height: height * 0.030)
                        Rectangle()
                            .fill(phosphorColor.opacity(0.95))
                            .frame(width: width * 0.030, height: height * 0.012)
                            .offset(y: height * 0.014)
                        Circle()
                            .fill(phosphorColor.opacity(0.95))
                            .frame(width: width * 0.008, height: width * 0.008)
                            .offset(x: -width * 0.014, y: -height * 0.006)
                        Circle()
                            .fill(phosphorColor.opacity(0.95))
                            .frame(width: width * 0.008, height: width * 0.008)
                            .offset(x: width * 0.014, y: -height * 0.006)
                    }
                    .position(x: x, y: y)
                }

                ForEach(spaceInvadersPlayerBullets) { bullet in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(phosphorColor)
                        .frame(width: max(2, width * 0.004), height: height * 0.032)
                        .position(x: width * bullet.x, y: height * bullet.y)
                }

                ForEach(spaceInvadersEnemyBullets) { bullet in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.red.opacity(0.85))
                        .frame(width: max(2, width * 0.004), height: height * 0.028)
                        .position(x: width * bullet.x, y: height * bullet.y)
                }

                ZStack {
                    Capsule(style: .continuous)
                        .fill(phosphorColor)
                        .frame(width: width * 0.075, height: height * 0.026)
                    Rectangle()
                        .fill(phosphorColor.opacity(0.92))
                        .frame(width: width * 0.018, height: height * 0.014)
                        .offset(y: -height * 0.012)
                }
                .position(x: width * spaceInvadersPlayerX, y: playerY)
                .shadow(color: phosphorColor.opacity(0.65), radius: 4)

                VStack(spacing: 4) {
                    Text("SPACE INVADERS  \(spaceInvadersScore)")
                        .font(displayFont(size: max(18, height * 0.085), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(spaceInvadersGameOver ? "GAME OVER" : (spaceInvadersRunning ? "RUN · WAVE \(spaceInvadersWave)" : "READY · WAVE \(spaceInvadersWave)"))
                        .font(.system(size: max(11, height * 0.05), weight: .regular, design: .monospaced))
                        .foregroundStyle(spaceInvadersGameOver ? Color.red : phosphorDim)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("←/→ mover · espacio disparar · enter start")
                    .font(.system(size: max(10, height * 0.040), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .contentShape(Rectangle())
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { spaceInvadersShoot() },
                    onRightClick: { resetSpaceInvadersGame() }
                )
            )
        }
    }

    func activateSpaceInvadersMode() {
        if spaceInvadersEnemies.isEmpty, spaceInvadersScore == 0 {
            resetSpaceInvadersGame(startRunning: false)
        }
        installSpaceInvadersKeyboardMonitorsIfNeeded()
        startSpaceInvadersTimerIfNeeded()
    }

    func deactivateSpaceInvadersMode() {
        spaceInvadersTimer?.setEventHandler {}
        spaceInvadersTimer?.cancel()
        spaceInvadersTimer = nil
        if let monitor = spaceInvadersKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            spaceInvadersKeyboardMonitor = nil
        }
        if let monitor = spaceInvadersKeyboardUpMonitor {
            NSEvent.removeMonitor(monitor)
            spaceInvadersKeyboardUpMonitor = nil
        }
        spaceInvadersMoveLeftPressed = false
        spaceInvadersMoveRightPressed = false
    }

    func installSpaceInvadersKeyboardMonitorsIfNeeded() {
        if spaceInvadersKeyboardMonitor == nil {
            spaceInvadersKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isGameActive(.spaceInvaders) else { return event }
                switch event.keyCode {
                case 123:
                    spaceInvadersMoveLeftPressed = true
                    return nil
                case 124:
                    spaceInvadersMoveRightPressed = true
                    return nil
                case 36:
                    spaceInvadersRunning.toggle()
                    return nil
                case 49:
                    spaceInvadersShoot()
                    return nil
                case 15:
                    resetSpaceInvadersGame()
                    return nil
                default:
                    return event
                }
            }
        }

        if spaceInvadersKeyboardUpMonitor == nil {
            spaceInvadersKeyboardUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
                guard isGameActive(.spaceInvaders) else { return event }
                switch event.keyCode {
                case 123:
                    spaceInvadersMoveLeftPressed = false
                    return nil
                case 124:
                    spaceInvadersMoveRightPressed = false
                    return nil
                default:
                    return event
                }
            }
        }
    }

    func startSpaceInvadersTimerIfNeeded() {
        guard spaceInvadersTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            updateSpaceInvadersFrame(deltaTime: CGFloat(Double(gameLoopIntervalMs) / 1000))
        }
        timer.resume()
        spaceInvadersTimer = timer
    }

    func resetSpaceInvadersGame(startRunning: Bool = false) {
        spaceInvadersRunning = startRunning
        spaceInvadersGameOver = false
        spaceInvadersScore = 0
        spaceInvadersWave = 1
        spaceInvadersPlayerX = 0.5
        spaceInvadersMoveLeftPressed = false
        spaceInvadersMoveRightPressed = false
        spaceInvadersFleetDirection = 1
        spaceInvadersEnemyShotCooldown = 0.65
        spaceInvadersPlayerBullets = []
        spaceInvadersEnemyBullets = []
        spawnSpaceInvadersWave()
    }

    func spawnSpaceInvadersWave() {
        let rows = 4
        let cols = 8
        let startX: CGFloat = 0.18
        let startY: CGFloat = 0.18
        let spacingX: CGFloat = 0.08
        let spacingY: CGFloat = 0.07
        var enemies: [InvaderEnemy] = []
        enemies.reserveCapacity(rows * cols)
        for row in 0..<rows {
            for col in 0..<cols {
                enemies.append(
                    InvaderEnemy(
                        x: startX + (CGFloat(col) * spacingX),
                        y: startY + (CGFloat(row) * spacingY),
                        type: row
                    )
                )
            }
        }
        spaceInvadersEnemies = enemies
        spaceInvadersFleetDirection = 1
        spaceInvadersEnemyShotCooldown = max(0.22, 0.75 - (CGFloat(spaceInvadersWave - 1) * 0.06))
    }

    func spaceInvadersShoot() {
        if spaceInvadersGameOver {
            resetSpaceInvadersGame(startRunning: true)
            return
        }
        if spaceInvadersRunning == false {
            spaceInvadersRunning = true
        }
        if spaceInvadersPlayerBullets.count >= 4 {
            return
        }
        spaceInvadersPlayerBullets.append(InvaderBullet(x: spaceInvadersPlayerX, y: 0.86))
    }

    func updateSpaceInvadersFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.spaceInvaders) else { return }
        guard spaceInvadersGameOver == false else { return }
        guard spaceInvadersRunning else { return }

        let playerSpeed: CGFloat = 0.95
        if spaceInvadersMoveLeftPressed {
            spaceInvadersPlayerX -= playerSpeed * dt
        }
        if spaceInvadersMoveRightPressed {
            spaceInvadersPlayerX += playerSpeed * dt
        }
        spaceInvadersPlayerX = max(0.06, min(0.94, spaceInvadersPlayerX))

        let fleetSpeed = min(0.26, 0.09 + CGFloat(spaceInvadersWave - 1) * 0.018)
        for index in spaceInvadersEnemies.indices {
            spaceInvadersEnemies[index].x += spaceInvadersFleetDirection * fleetSpeed * dt
        }

        let minX = spaceInvadersEnemies.map(\.x).min() ?? 0
        let maxX = spaceInvadersEnemies.map(\.x).max() ?? 1
        if minX <= 0.08 || maxX >= 0.92 {
            spaceInvadersFleetDirection *= -1
            for index in spaceInvadersEnemies.indices {
                spaceInvadersEnemies[index].y += 0.024
            }
        }

        if spaceInvadersEnemies.contains(where: { $0.y >= 0.84 }) {
            spaceInvadersRunning = false
            spaceInvadersGameOver = true
            return
        }

        for index in spaceInvadersPlayerBullets.indices {
            spaceInvadersPlayerBullets[index].y -= dt * 1.25
        }
        for index in spaceInvadersEnemyBullets.indices {
            spaceInvadersEnemyBullets[index].y += dt * 0.76
        }
        spaceInvadersPlayerBullets.removeAll { $0.y < -0.04 }
        spaceInvadersEnemyBullets.removeAll { $0.y > 1.04 }

        var deadEnemyIDs = Set<UUID>()
        var deadPlayerBulletIDs = Set<UUID>()
        for bullet in spaceInvadersPlayerBullets {
            for enemy in spaceInvadersEnemies {
                if abs(bullet.x - enemy.x) < 0.028, abs(bullet.y - enemy.y) < 0.028 {
                    deadEnemyIDs.insert(enemy.id)
                    deadPlayerBulletIDs.insert(bullet.id)
                    spaceInvadersScore += (10 + (3 - enemy.type) * 4)
                    break
                }
            }
        }
        if deadEnemyIDs.isEmpty == false {
            spaceInvadersEnemies.removeAll { deadEnemyIDs.contains($0.id) }
        }
        if deadPlayerBulletIDs.isEmpty == false {
            spaceInvadersPlayerBullets.removeAll { deadPlayerBulletIDs.contains($0.id) }
        }

        spaceInvadersEnemyShotCooldown -= dt
        if spaceInvadersEnemyShotCooldown <= 0, let shooter = spaceInvadersEnemies.randomElement() {
            spaceInvadersEnemyBullets.append(InvaderBullet(x: shooter.x, y: shooter.y + 0.02))
            let cooldownMin = max(0.16, 0.48 - CGFloat(spaceInvadersWave - 1) * 0.03)
            let cooldownMax = cooldownMin + 0.35
            spaceInvadersEnemyShotCooldown = CGFloat.random(in: cooldownMin...cooldownMax)
        }

        for bullet in spaceInvadersEnemyBullets {
            if abs(bullet.x - spaceInvadersPlayerX) < 0.038, bullet.y >= 0.86, bullet.y <= 0.93 {
                spaceInvadersRunning = false
                spaceInvadersGameOver = true
                triggerFlash(reason: .spaceInvadersPlayerHit)
                return
            }
        }

        if spaceInvadersEnemies.isEmpty {
            spaceInvadersWave += 1
            spaceInvadersPlayerBullets.removeAll()
            spaceInvadersEnemyBullets.removeAll()
            spawnSpaceInvadersWave()
        }
    }

    var asteroidsView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.94
            let height = geometry.size.height
            let shipX = width * asteroidsShipX
            let shipY = height * asteroidsShipY
            let shipSize = min(width, height) * 0.028

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(asteroidsRocks) { rock in
                    Circle()
                        .stroke(phosphorColor.opacity(0.9), lineWidth: 2)
                        .frame(width: width * rock.radius * 2, height: width * rock.radius * 2)
                        .position(x: width * rock.x, y: height * rock.y)
                }

                ForEach(asteroidsBullets) { bullet in
                    Circle()
                        .fill(phosphorColor)
                        .frame(width: 4, height: 4)
                        .position(x: width * bullet.x, y: height * bullet.y)
                }

                Path { path in
                    let nose = CGPoint(x: shipX + cos(asteroidsShipAngle) * shipSize * 1.2, y: shipY + sin(asteroidsShipAngle) * shipSize * 1.2)
                    let left = CGPoint(x: shipX + cos(asteroidsShipAngle + .pi * 0.78) * shipSize, y: shipY + sin(asteroidsShipAngle + .pi * 0.78) * shipSize)
                    let right = CGPoint(x: shipX + cos(asteroidsShipAngle - .pi * 0.78) * shipSize, y: shipY + sin(asteroidsShipAngle - .pi * 0.78) * shipSize)
                    path.move(to: nose)
                    path.addLine(to: left)
                    path.addLine(to: right)
                    path.closeSubpath()
                }
                .stroke(phosphorColor, lineWidth: 2)

                if asteroidsThrustPressed && asteroidsRunning && asteroidsGameOver == false {
                    Circle()
                        .fill(phosphorColor.opacity(0.7))
                        .frame(width: shipSize * 0.55, height: shipSize * 0.55)
                        .position(
                            x: shipX - cos(asteroidsShipAngle) * shipSize * 0.9,
                            y: shipY - sin(asteroidsShipAngle) * shipSize * 0.9
                        )
                }

                VStack(spacing: 4) {
                    Text("ASTEROIDS  \(asteroidsScore)")
                        .font(displayFont(size: max(18, height * 0.085), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text(asteroidsGameOver ? "GAME OVER" : (asteroidsRunning ? "RUN" : "READY"))
                        .font(.system(size: max(11, height * 0.05), weight: .regular, design: .monospaced))
                        .foregroundStyle(asteroidsGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("←/→ giro · ↑ thrust · espacio disparar · enter start")
                    .font(.system(size: max(10, height * 0.040), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { asteroidsShoot() },
                    onRightClick: { resetAsteroidsGame() }
                )
            )
        }
    }

    func activateAsteroidsMode() {
        if asteroidsRocks.isEmpty && asteroidsScore == 0 {
            resetAsteroidsGame(startRunning: false)
        }
        installAsteroidsKeyboardMonitorsIfNeeded()
        startAsteroidsTimerIfNeeded()
    }

    func deactivateAsteroidsMode() {
        asteroidsTimer?.setEventHandler {}
        asteroidsTimer?.cancel()
        asteroidsTimer = nil
        if let monitor = asteroidsKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            asteroidsKeyboardMonitor = nil
        }
        if let monitor = asteroidsKeyboardUpMonitor {
            NSEvent.removeMonitor(monitor)
            asteroidsKeyboardUpMonitor = nil
        }
        asteroidsTurnLeftPressed = false
        asteroidsTurnRightPressed = false
        asteroidsThrustPressed = false
    }

    func installAsteroidsKeyboardMonitorsIfNeeded() {
        if asteroidsKeyboardMonitor == nil {
            asteroidsKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isGameActive(.asteroids) else { return event }
                switch event.keyCode {
                case 123:
                    asteroidsTurnLeftPressed = true
                    return nil
                case 124:
                    asteroidsTurnRightPressed = true
                    return nil
                case 126:
                    asteroidsThrustPressed = true
                    return nil
                case 125:
                    teleportAsteroidsShip()
                    return nil
                case 49:
                    asteroidsShoot()
                    return nil
                case 36:
                    asteroidsRunning.toggle()
                    return nil
                case 15:
                    resetAsteroidsGame()
                    return nil
                default:
                    return event
                }
            }
        }
        if asteroidsKeyboardUpMonitor == nil {
            asteroidsKeyboardUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
                guard isGameActive(.asteroids) else { return event }
                switch event.keyCode {
                case 123:
                    asteroidsTurnLeftPressed = false
                    return nil
                case 124:
                    asteroidsTurnRightPressed = false
                    return nil
                case 126:
                    asteroidsThrustPressed = false
                    return nil
                default:
                    return event
                }
            }
        }
    }

    func startAsteroidsTimerIfNeeded() {
        guard asteroidsTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            updateAsteroidsFrame(deltaTime: CGFloat(Double(gameLoopIntervalMs) / 1000))
        }
        timer.resume()
        asteroidsTimer = timer
    }

    func resetAsteroidsGame(startRunning: Bool = false) {
        asteroidsRunning = startRunning
        asteroidsGameOver = false
        asteroidsScore = 0
        asteroidsShipX = 0.5
        asteroidsShipY = 0.52
        asteroidsShipVX = 0
        asteroidsShipVY = 0
        asteroidsShipAngle = -.pi / 2
        asteroidsTurnLeftPressed = false
        asteroidsTurnRightPressed = false
        asteroidsThrustPressed = false
        asteroidsBullets = []
        asteroidsRocks = []
        spawnAsteroidsWave(count: 5)
    }

    func spawnAsteroidsWave(count: Int) {
        var rocks: [AsteroidsRock] = []
        for _ in 0..<count {
            let radius = CGFloat.random(in: 0.035...0.06)
            rocks.append(
                AsteroidsRock(
                    x: CGFloat.random(in: 0.08...0.92),
                    y: CGFloat.random(in: 0.08...0.92),
                    vx: CGFloat.random(in: -0.18...0.18),
                    vy: CGFloat.random(in: -0.18...0.18),
                    radius: radius,
                    size: 3
                )
            )
        }
        asteroidsRocks = rocks
    }

    func asteroidsShoot() {
        if asteroidsGameOver {
            resetAsteroidsGame(startRunning: true)
            return
        }
        if asteroidsRunning == false {
            asteroidsRunning = true
        }
        if asteroidsBullets.count >= 8 {
            return
        }
        let speed: CGFloat = 0.85
        asteroidsBullets.append(
            AsteroidsProjectile(
                x: asteroidsShipX + cos(asteroidsShipAngle) * 0.018,
                y: asteroidsShipY + sin(asteroidsShipAngle) * 0.018,
                vx: cos(asteroidsShipAngle) * speed + asteroidsShipVX * 0.2,
                vy: sin(asteroidsShipAngle) * speed + asteroidsShipVY * 0.2,
                life: 1.15
            )
        )
    }

    func teleportAsteroidsShip() {
        guard isGameActive(.asteroids) else { return }
        guard asteroidsRocks.isEmpty == false else {
            asteroidsShipX = CGFloat.random(in: 0.12...0.88)
            asteroidsShipY = CGFloat.random(in: 0.12...0.82)
            triggerFlash()
            return
        }

        var bestPoint = CGPoint(x: asteroidsShipX, y: asteroidsShipY)
        var bestSafety: CGFloat = -1
        for _ in 0..<42 {
            let candidate = CGPoint(x: CGFloat.random(in: 0.08...0.92), y: CGFloat.random(in: 0.08...0.86))
            var minDist: CGFloat = .greatestFiniteMagnitude
            for rock in asteroidsRocks {
                let dx = candidate.x - rock.x
                let dy = candidate.y - rock.y
                minDist = min(minDist, sqrt(dx * dx + dy * dy) - rock.radius)
            }
            if minDist > bestSafety {
                bestSafety = minDist
                bestPoint = candidate
            }
        }

        asteroidsShipX = bestPoint.x
        asteroidsShipY = bestPoint.y
        asteroidsShipVX *= 0.2
        asteroidsShipVY *= 0.2
        triggerFlash()
        if bestSafety < 0.02 {
            asteroidsShipAngle = CGFloat.random(in: -CGFloat.pi...CGFloat.pi)
        }
    }

    func updateAsteroidsFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.asteroids) else { return }
        guard asteroidsGameOver == false else { return }
        guard asteroidsRunning else { return }

        if asteroidsTurnLeftPressed {
            asteroidsShipAngle -= dt * 4.2
        }
        if asteroidsTurnRightPressed {
            asteroidsShipAngle += dt * 4.2
        }
        if asteroidsThrustPressed {
            asteroidsShipVX += cos(asteroidsShipAngle) * dt * 0.7
            asteroidsShipVY += sin(asteroidsShipAngle) * dt * 0.7
        }

        asteroidsShipVX *= 0.993
        asteroidsShipVY *= 0.993
        asteroidsShipX = wrap01(asteroidsShipX + asteroidsShipVX * dt)
        asteroidsShipY = wrap01(asteroidsShipY + asteroidsShipVY * dt)

        for index in asteroidsRocks.indices {
            asteroidsRocks[index].x = wrap01(asteroidsRocks[index].x + asteroidsRocks[index].vx * dt)
            asteroidsRocks[index].y = wrap01(asteroidsRocks[index].y + asteroidsRocks[index].vy * dt)
        }

        for index in asteroidsBullets.indices {
            asteroidsBullets[index].x = wrap01(asteroidsBullets[index].x + asteroidsBullets[index].vx * dt)
            asteroidsBullets[index].y = wrap01(asteroidsBullets[index].y + asteroidsBullets[index].vy * dt)
            asteroidsBullets[index].life -= dt
        }
        asteroidsBullets.removeAll { $0.life <= 0 }

        var rockIDsToRemove = Set<UUID>()
        var bulletIDsToRemove = Set<UUID>()
        var spawnedRocks: [AsteroidsRock] = []

        for bullet in asteroidsBullets {
            for rock in asteroidsRocks {
                let dx = bullet.x - rock.x
                let dy = bullet.y - rock.y
                if (dx * dx + dy * dy) <= (rock.radius * rock.radius) {
                    rockIDsToRemove.insert(rock.id)
                    bulletIDsToRemove.insert(bullet.id)
                    asteroidsScore += (4 - rock.size) * 25
                    if rock.size > 1 {
                        for _ in 0..<2 {
                            spawnedRocks.append(
                                AsteroidsRock(
                                    x: rock.x,
                                    y: rock.y,
                                    vx: rock.vx + CGFloat.random(in: -0.22...0.22),
                                    vy: rock.vy + CGFloat.random(in: -0.22...0.22),
                                    radius: rock.radius * 0.62,
                                    size: rock.size - 1
                                )
                            )
                        }
                    }
                    break
                }
            }
        }

        if rockIDsToRemove.isEmpty == false {
            asteroidsRocks.removeAll { rockIDsToRemove.contains($0.id) }
            asteroidsRocks.append(contentsOf: spawnedRocks)
        }
        if bulletIDsToRemove.isEmpty == false {
            asteroidsBullets.removeAll { bulletIDsToRemove.contains($0.id) }
        }

        for rock in asteroidsRocks {
            let dx = asteroidsShipX - rock.x
            let dy = asteroidsShipY - rock.y
            let hitDistance = rock.radius + 0.016
            if (dx * dx + dy * dy) <= (hitDistance * hitDistance) {
                asteroidsRunning = false
                asteroidsGameOver = true
                triggerFlash()
                return
            }
        }

        if asteroidsRocks.isEmpty {
            spawnAsteroidsWave(count: min(10, 5 + (asteroidsScore / 400)))
        }
    }

    func wrap01(_ value: CGFloat) -> CGFloat {
        if value < 0 { return value + 1 }
        if value > 1 { return value - 1 }
        return value
    }

    var tronView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height * 0.88
            let cell = min(width / CGFloat(tronCols), height / CGFloat(tronRows))
            let boardWidth = cell * CGFloat(tronCols)
            let boardHeight = cell * CGFloat(tronRows)
            let ox = (geometry.size.width - boardWidth) * 0.5
            let oy = (geometry.size.height - boardHeight) * 0.5

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(0..<tronRows, id: \.self) { row in
                    ForEach(0..<tronCols, id: \.self) { col in
                        if tronTrailKeys.contains("\(col),\(row)") {
                            Rectangle()
                                .fill(phosphorColor.opacity(0.55))
                                .frame(width: cell - 1, height: cell - 1)
                                .position(x: ox + (CGFloat(col) + 0.5) * cell, y: oy + (CGFloat(row) + 0.5) * cell)
                        }
                    }
                }

                Rectangle()
                    .fill(phosphorColor)
                    .frame(width: cell - 1, height: cell - 1)
                    .position(x: ox + (CGFloat(tronPlayerPos.x) + 0.5) * cell, y: oy + (CGFloat(tronPlayerPos.y) + 0.5) * cell)

                Rectangle()
                    .fill(Color.red.opacity(0.85))
                    .frame(width: cell - 1, height: cell - 1)
                    .position(x: ox + (CGFloat(tronEnemyPos.x) + 0.5) * cell, y: oy + (CGFloat(tronEnemyPos.y) + 0.5) * cell)

                VStack(spacing: 4) {
                    Text("TRON  \(tronScore)")
                        .font(displayFont(size: max(18, geometry.size.height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                    Text(tronGameOver ? "GAME OVER" : (tronRunning ? "RUN" : "READY"))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(tronGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("↑/↓/←/→ mover · enter start · R reset")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { tronRunning.toggle() },
                    onRightClick: { resetTronGame() }
                )
            )
        }
    }

    func activateTronMode() {
        if tronTrailKeys.isEmpty {
            resetTronGame(startRunning: false)
        }
        installTronKeyboardMonitorIfNeeded()
        startTronTimerIfNeeded()
    }

    func deactivateTronMode() {
        tronTimer?.setEventHandler {}
        tronTimer?.cancel()
        tronTimer = nil
        if let monitor = tronKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            tronKeyboardMonitor = nil
        }
    }

    func installTronKeyboardMonitorIfNeeded() {
        guard tronKeyboardMonitor == nil else { return }
        tronKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.tron) else { return event }
            switch event.keyCode {
            case 123:
                setTronDirection(SIMD2<Int>(-1, 0))
                return nil
            case 124:
                setTronDirection(SIMD2<Int>(1, 0))
                return nil
            case 125:
                setTronDirection(SIMD2<Int>(0, 1))
                return nil
            case 126:
                setTronDirection(SIMD2<Int>(0, -1))
                return nil
            case 36:
                tronRunning.toggle()
                return nil
            case 15:
                resetTronGame()
                return nil
            default:
                return event
            }
        }
    }

    func setTronDirection(_ dir: SIMD2<Int>) {
        if tronPlayerDir.x + dir.x == 0, tronPlayerDir.y + dir.y == 0 {
            return
        }
        tronPlayerDir = dir
        if tronRunning == false {
            tronRunning = true
        }
    }

    func startTronTimerIfNeeded() {
        guard tronTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(70), leeway: .milliseconds(6))
        timer.setEventHandler { updateTronStep() }
        timer.resume()
        tronTimer = timer
    }

    func resetTronGame(startRunning: Bool = false) {
        tronRunning = startRunning
        tronGameOver = false
        tronScore = 0
        tronPlayerPos = SIMD2<Int>(6, 9)
        tronEnemyPos = SIMD2<Int>(27, 9)
        tronPlayerDir = SIMD2<Int>(1, 0)
        tronEnemyDir = SIMD2<Int>(-1, 0)
        tronTrailKeys = [tronKey(tronPlayerPos), tronKey(tronEnemyPos)]
    }

    func tronKey(_ p: SIMD2<Int>) -> String { "\(p.x),\(p.y)" }

    func updateTronStep() {
        guard isGameActive(.tron), tronRunning, tronGameOver == false else { return }

        if let smarterDirection = tronBestEnemyDirection() {
            tronEnemyDir = smarterDirection
        }

        let nextPlayer = SIMD2<Int>(tronPlayerPos.x + tronPlayerDir.x, tronPlayerPos.y + tronPlayerDir.y)
        let nextEnemy = SIMD2<Int>(tronEnemyPos.x + tronEnemyDir.x, tronEnemyPos.y + tronEnemyDir.y)

        let playerDead = nextPlayer.x < 0 || nextPlayer.x >= tronCols || nextPlayer.y < 0 || nextPlayer.y >= tronRows || tronTrailKeys.contains(tronKey(nextPlayer))
        let enemyDead = nextEnemy.x < 0 || nextEnemy.x >= tronCols || nextEnemy.y < 0 || nextEnemy.y >= tronRows || tronTrailKeys.contains(tronKey(nextEnemy))
        let headOn = nextPlayer == nextEnemy

        if playerDead || headOn {
            tronRunning = false
            tronGameOver = true
            triggerFlash()
            return
        }

        tronPlayerPos = nextPlayer
        tronTrailKeys.insert(tronKey(tronPlayerPos))
        tronScore += 1

        if enemyDead == false {
            tronEnemyPos = nextEnemy
            tronTrailKeys.insert(tronKey(tronEnemyPos))
        } else {
            tronScore += 120
            triggerFlash()
            resetTronGame(startRunning: true)
        }
    }

    func tronBestEnemyDirection() -> SIMD2<Int>? {
        let choices = [SIMD2<Int>(1, 0), SIMD2<Int>(-1, 0), SIMD2<Int>(0, 1), SIMD2<Int>(0, -1)].filter { dir in
            !(tronEnemyDir.x + dir.x == 0 && tronEnemyDir.y + dir.y == 0)
        }
        var best: SIMD2<Int>?
        var bestScore = Int.min

        for dir in choices {
            let next = SIMD2<Int>(tronEnemyPos.x + dir.x, tronEnemyPos.y + dir.y)
            guard tronCellIsFree(next) else { continue }

            let reachable = tronReachableCells(from: next, maxNodes: 120)
            let distanceToPlayer = abs(next.x - tronPlayerPos.x) + abs(next.y - tronPlayerPos.y)
            let nearPlayerBonus = max(0, 24 - distanceToPlayer)
            let score = (reachable * 12) + nearPlayerBonus

            if score > bestScore {
                bestScore = score
                best = dir
            }
        }
        return best
    }

    func tronCellIsFree(_ p: SIMD2<Int>) -> Bool {
        p.x >= 0 && p.x < tronCols && p.y >= 0 && p.y < tronRows && tronTrailKeys.contains(tronKey(p)) == false
    }

    func tronReachableCells(from start: SIMD2<Int>, maxNodes: Int) -> Int {
        var queue: [SIMD2<Int>] = [start]
        var visited: Set<String> = [tronKey(start)]
        var idx = 0
        while idx < queue.count, visited.count < maxNodes {
            let p = queue[idx]
            idx += 1
            let neighbors = [
                SIMD2<Int>(p.x + 1, p.y),
                SIMD2<Int>(p.x - 1, p.y),
                SIMD2<Int>(p.x, p.y + 1),
                SIMD2<Int>(p.x, p.y - 1)
            ]
            for n in neighbors where tronCellIsFree(n) {
                let key = tronKey(n)
                if visited.insert(key).inserted {
                    queue.append(n)
                }
            }
        }
        return visited.count
    }

    var pacmanView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.92
            let height = geometry.size.height * 0.88
            let cell = min(width / CGFloat(pacmanCols), height / CGFloat(pacmanRows))
            let boardWidth = cell * CGFloat(pacmanCols)
            let boardHeight = cell * CGFloat(pacmanRows)
            let ox = (geometry.size.width - boardWidth) * 0.5
            let oy = (geometry.size.height - boardHeight) * 0.5

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(0..<pacmanRows, id: \.self) { row in
                    ForEach(0..<pacmanCols, id: \.self) { col in
                        if pacmanIsWall(col: col, row: row) {
                            Rectangle()
                                .fill(phosphorColor.opacity(0.28))
                                .frame(width: cell - 1, height: cell - 1)
                                .position(x: ox + (CGFloat(col) + 0.5) * cell, y: oy + (CGFloat(row) + 0.5) * cell)
                        } else if pacmanPowerPelletKeys.contains("\(col),\(row)") {
                            Circle()
                                .fill(phosphorColor.opacity(0.96))
                                .frame(width: max(4, cell * 0.42), height: max(4, cell * 0.42))
                                .position(x: ox + (CGFloat(col) + 0.5) * cell, y: oy + (CGFloat(row) + 0.5) * cell)
                        } else if pacmanPelletKeys.contains("\(col),\(row)") {
                            Circle()
                                .fill(phosphorColor.opacity(0.85))
                                .frame(width: max(2, cell * 0.2), height: max(2, cell * 0.2))
                                .position(x: ox + (CGFloat(col) + 0.5) * cell, y: oy + (CGFloat(row) + 0.5) * cell)
                        }
                    }
                }

                Circle()
                    .fill(phosphorColor)
                    .frame(width: cell * 0.78, height: cell * 0.78)
                    .position(x: ox + (CGFloat(pacmanPlayerPos.x) + 0.5) * cell, y: oy + (CGFloat(pacmanPlayerPos.y) + 0.5) * cell)

                ForEach(Array(pacmanGhosts.enumerated()), id: \.offset) { _, ghost in
                    RoundedRectangle(cornerRadius: cell * 0.25, style: .continuous)
                        .fill((pacmanPoweredRemaining > 0 ? Color.blue : Color.red).opacity(0.85))
                        .frame(width: cell * 0.78, height: cell * 0.78)
                        .position(x: ox + (CGFloat(ghost.x) + 0.5) * cell, y: oy + (CGFloat(ghost.y) + 0.5) * cell)
                }

                VStack(spacing: 4) {
                    Text("PAC-MAN  \(pacmanScore)")
                        .font(displayFont(size: max(18, geometry.size.height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                    Text(pacmanGameOver ? "GAME OVER" : (pacmanRunning ? "RUN" : "READY") + (pacmanPoweredRemaining > 0 ? " · POWER" : ""))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(pacmanGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("↑/↓/←/→ mover · enter start · R reset")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { pacmanRunning.toggle() },
                    onRightClick: { resetPacmanGame() }
                )
            )
        }
    }

    func activatePacmanMode() {
        if pacmanPelletKeys.isEmpty {
            resetPacmanGame(startRunning: false)
        }
        installPacmanKeyboardMonitorIfNeeded()
        startPacmanTimerIfNeeded()
    }

    func deactivatePacmanMode() {
        pacmanTimer?.setEventHandler {}
        pacmanTimer?.cancel()
        pacmanTimer = nil
        if let monitor = pacmanKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            pacmanKeyboardMonitor = nil
        }
    }

    func installPacmanKeyboardMonitorIfNeeded() {
        guard pacmanKeyboardMonitor == nil else { return }
        pacmanKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.pacman) else { return event }
            switch event.keyCode {
            case 123:
                pacmanPendingDirection = SIMD2<Int>(-1, 0)
                pacmanRunning = true
                return nil
            case 124:
                pacmanPendingDirection = SIMD2<Int>(1, 0)
                pacmanRunning = true
                return nil
            case 125:
                pacmanPendingDirection = SIMD2<Int>(0, 1)
                pacmanRunning = true
                return nil
            case 126:
                pacmanPendingDirection = SIMD2<Int>(0, -1)
                pacmanRunning = true
                return nil
            case 36:
                pacmanRunning.toggle()
                return nil
            case 15:
                resetPacmanGame()
                return nil
            default:
                return event
            }
        }
    }

    func startPacmanTimerIfNeeded() {
        guard pacmanTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(150), leeway: .milliseconds(10))
        timer.setEventHandler { updatePacmanStep() }
        timer.resume()
        pacmanTimer = timer
    }

    func resetPacmanGame(startRunning: Bool = false) {
        pacmanRunning = startRunning
        pacmanGameOver = false
        pacmanScore = 0
        pacmanCols = pacmanMazeLayout.first?.count ?? 21
        pacmanRows = pacmanMazeLayout.count
        pacmanPlayerPos = SIMD2<Int>(10, 11)
        pacmanDirection = SIMD2<Int>(0, 0)
        pacmanPendingDirection = SIMD2<Int>(0, 0)
        pacmanPoweredRemaining = 0
        pacmanGhosts = [SIMD2<Int>(10, 5), SIMD2<Int>(9, 5), SIMD2<Int>(11, 5)]
        pacmanPelletKeys = []
        pacmanPowerPelletKeys = []
        for row in 0..<pacmanRows {
            let chars = Array(pacmanMazeLayout[row])
            for col in 0..<pacmanCols {
                guard col < chars.count else { continue }
                let ch = chars[col]
                if ch == "." {
                    pacmanPelletKeys.insert("\(col),\(row)")
                } else if ch == "o" {
                    pacmanPowerPelletKeys.insert("\(col),\(row)")
                }
            }
        }
        pacmanPelletKeys.remove("\(pacmanPlayerPos.x),\(pacmanPlayerPos.y)")
    }

    var pacmanMazeLayout: [String] {
        [
            "#####################",
            "#o.......#.......o..#",
            "#.###.##.#.##.###.###",
            "#.....##...##.......#",
            "###.#.#####.#####.#.#",
            "#...#...#.....#...#.#",
            "#.#####.# ### #.###.#",
            "#.......#     #.....#",
            "#.#####.# ### #.###.#",
            "#...#...#.....#...#.#",
            "###.#.#####.#####.#.#",
            "#.....##...##.......#",
            "#.###.##.#.##.###.###",
            "#o.......#.......o..#",
            "#####################"
        ]
    }

    func pacmanIsWall(col: Int, row: Int) -> Bool {
        guard row >= 0, row < pacmanMazeLayout.count else { return true }
        let chars = Array(pacmanMazeLayout[row])
        guard col >= 0, col < chars.count else { return true }
        return chars[col] == "#"
    }

    func pacmanGhostHome(for index: Int) -> SIMD2<Int> {
        switch index {
        case 0: return SIMD2<Int>(10, 5)
        case 1: return SIMD2<Int>(9, 5)
        default: return SIMD2<Int>(11, 5)
        }
    }

    func pacmanTargetForGhost(index: Int) -> SIMD2<Int> {
        switch index % 3 {
        case 0:
            return pacmanPlayerPos
        case 1:
            return SIMD2<Int>(pacmanPlayerPos.x - 2, pacmanPlayerPos.y + 1)
        default:
            return SIMD2<Int>(pacmanPlayerPos.x + 2, pacmanPlayerPos.y - 1)
        }
    }

    func pacmanDirectionOrder(for ghost: SIMD2<Int>, ghostIndex: Int, reserved: Set<String>) -> [SIMD2<Int>] {
        let dirs = [SIMD2<Int>(1, 0), SIMD2<Int>(-1, 0), SIMD2<Int>(0, 1), SIMD2<Int>(0, -1)]
        let target = pacmanTargetForGhost(index: ghostIndex)
        return dirs.sorted { lhs, rhs in
            let aPos = SIMD2<Int>(ghost.x + lhs.x, ghost.y + lhs.y)
            let bPos = SIMD2<Int>(ghost.x + rhs.x, ghost.y + rhs.y)

            func score(_ pos: SIMD2<Int>) -> Int {
                if pos.x < 0 || pos.x >= pacmanCols || pos.y < 0 || pos.y >= pacmanRows { return Int.min / 4 }
                if pacmanIsWall(col: pos.x, row: pos.y) { return Int.min / 4 }
                let key = "\(pos.x),\(pos.y)"
                if reserved.contains(key), pos != pacmanPlayerPos { return Int.min / 5 }

                let targetDist = abs(pos.x - target.x) + abs(pos.y - target.y)
                let playerDist = abs(pos.x - pacmanPlayerPos.x) + abs(pos.y - pacmanPlayerPos.y)

                var nearestGhostDist = 99
                for other in pacmanGhosts {
                    if other == ghost { continue }
                    nearestGhostDist = min(nearestGhostDist, abs(pos.x - other.x) + abs(pos.y - other.y))
                }

                if pacmanPoweredRemaining > 0 {
                    return (playerDist * 16) + (nearestGhostDist * 6)
                } else {
                    return (-targetDist * 16) + (nearestGhostDist * 7)
                }
            }

            return score(aPos) > score(bPos)
        }
    }

    func updatePacmanStep() {
        guard isGameActive(.pacman), pacmanRunning, pacmanGameOver == false else { return }
        if pacmanPoweredRemaining > 0 {
            pacmanPoweredRemaining -= 1
        }

        let preferred = SIMD2<Int>(pacmanPlayerPos.x + pacmanPendingDirection.x, pacmanPlayerPos.y + pacmanPendingDirection.y)
        if pacmanPendingDirection != SIMD2<Int>(0, 0),
           preferred.x >= 0, preferred.x < pacmanCols, preferred.y >= 0, preferred.y < pacmanRows,
           pacmanIsWall(col: preferred.x, row: preferred.y) == false {
            pacmanDirection = pacmanPendingDirection
        }

        let next = SIMD2<Int>(pacmanPlayerPos.x + pacmanDirection.x, pacmanPlayerPos.y + pacmanDirection.y)
        if next.x >= 0, next.x < pacmanCols, next.y >= 0, next.y < pacmanRows, pacmanIsWall(col: next.x, row: next.y) == false {
            pacmanPlayerPos = next
        }

        let pelletKey = "\(pacmanPlayerPos.x),\(pacmanPlayerPos.y)"
        if pacmanPelletKeys.remove(pelletKey) != nil {
            pacmanScore += 10
        }
        if pacmanPowerPelletKeys.remove(pelletKey) != nil {
            pacmanScore += 50
            pacmanPoweredRemaining = 44
        }

        var reservedGhostCells = Set<String>()
        for index in pacmanGhosts.indices {
            var moved = false
            for dir in pacmanDirectionOrder(for: pacmanGhosts[index], ghostIndex: index, reserved: reservedGhostCells) {
                let np = SIMD2<Int>(pacmanGhosts[index].x + dir.x, pacmanGhosts[index].y + dir.y)
                if np.x >= 0, np.x < pacmanCols, np.y >= 0, np.y < pacmanRows, pacmanIsWall(col: np.x, row: np.y) == false {
                    let key = "\(np.x),\(np.y)"
                    if reservedGhostCells.contains(key), np != pacmanPlayerPos {
                        continue
                    }
                    pacmanGhosts[index] = np
                    reservedGhostCells.insert(key)
                    moved = true
                    break
                }
            }
            if moved == false {
                reservedGhostCells.insert("\(pacmanGhosts[index].x),\(pacmanGhosts[index].y)")
            }
        }

        for index in pacmanGhosts.indices where pacmanGhosts[index] == pacmanPlayerPos {
            if pacmanPoweredRemaining > 0 {
                pacmanScore += 200
                pacmanGhosts[index] = pacmanGhostHome(for: index)
            } else {
                pacmanRunning = false
                pacmanGameOver = true
                triggerFlash()
                return
            }
        }

        if pacmanPelletKeys.isEmpty && pacmanPowerPelletKeys.isEmpty {
            pacmanScore += 200
            resetPacmanGame(startRunning: true)
        }
    }

    var froggerView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.9
            let height = geometry.size.height * 0.88
            let cell = min(width / CGFloat(froggerCols), height / CGFloat(froggerRows))
            let boardWidth = cell * CGFloat(froggerCols)
            let boardHeight = cell * CGFloat(froggerRows)
            let ox = (geometry.size.width - boardWidth) * 0.5
            let oy = (geometry.size.height - boardHeight) * 0.5

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                ForEach(0..<froggerRows, id: \.self) { row in
                    Rectangle()
                        .fill((row >= 2 && row <= 5) ? Color.blue.opacity(0.12) : Color.black.opacity(0.08))
                        .frame(width: boardWidth, height: cell)
                        .position(x: ox + boardWidth * 0.5, y: oy + (CGFloat(row) + 0.5) * cell)
                }

                ForEach(froggerObstacles) { obstacle in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(obstacle.isLog ? phosphorColor.opacity(0.65) : Color.red.opacity(0.8))
                        .frame(width: obstacle.width * boardWidth, height: cell * 0.72)
                        .position(
                            x: ox + obstacle.x * boardWidth,
                            y: oy + (CGFloat(obstacle.lane) + 0.5) * cell
                        )
                }

                Circle()
                    .fill(phosphorColor)
                    .frame(width: cell * 0.72, height: cell * 0.72)
                    .position(x: ox + (CGFloat(froggerPlayerCol) + 0.5) * cell, y: oy + (CGFloat(froggerPlayerRow) + 0.5) * cell)

                VStack(spacing: 4) {
                    Text("FROGGER  \(froggerScore)")
                        .font(displayFont(size: max(18, geometry.size.height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                    Text(froggerGameOver ? "GAME OVER" : (froggerRunning ? "RUN" : "READY"))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(froggerGameOver ? Color.red : phosphorDim)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text("↑/↓/←/→ mover · enter start · R reset")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { froggerRunning.toggle() },
                    onRightClick: { resetFroggerGame() }
                )
            )
        }
    }

    func activateFroggerMode() {
        if froggerObstacles.isEmpty {
            resetFroggerGame(startRunning: false)
        }
        installFroggerKeyboardMonitorIfNeeded()
        startFroggerTimerIfNeeded()
    }

    func deactivateFroggerMode() {
        froggerTimer?.setEventHandler {}
        froggerTimer?.cancel()
        froggerTimer = nil
        if let monitor = froggerKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            froggerKeyboardMonitor = nil
        }
    }

    func installFroggerKeyboardMonitorIfNeeded() {
        guard froggerKeyboardMonitor == nil else { return }
        froggerKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.frogger) else { return event }
            switch event.keyCode {
            case 123:
                froggerPlayerCol = max(0, froggerPlayerCol - 1)
                froggerCarryAccumulator = 0
                froggerRunning = true
                return nil
            case 124:
                froggerPlayerCol = min(froggerCols - 1, froggerPlayerCol + 1)
                froggerCarryAccumulator = 0
                froggerRunning = true
                return nil
            case 125:
                froggerPlayerRow = min(froggerRows - 1, froggerPlayerRow + 1)
                froggerCarryAccumulator = 0
                froggerRunning = true
                return nil
            case 126:
                froggerPlayerRow = max(0, froggerPlayerRow - 1)
                froggerCarryAccumulator = 0
                froggerRunning = true
                return nil
            case 36:
                froggerRunning.toggle()
                return nil
            case 15:
                resetFroggerGame()
                return nil
            default:
                return event
            }
        }
    }

    func startFroggerTimerIfNeeded() {
        guard froggerTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(gameLoopIntervalMs), leeway: .milliseconds(gameLoopLeewayMs))
        timer.setEventHandler {
            updateFroggerFrame(deltaTime: CGFloat(Double(gameLoopIntervalMs) / 1000))
        }
        timer.resume()
        froggerTimer = timer
    }

    func resetFroggerGame(startRunning: Bool = false) {
        froggerRunning = startRunning
        froggerGameOver = false
        froggerScore = 0
        froggerPlayerCol = froggerCols / 2
        froggerPlayerRow = froggerRows - 1
        froggerCarryAccumulator = 0
        froggerObstacles = []

        for lane in 2...5 {
            for _ in 0..<3 {
                froggerObstacles.append(
                    FroggerObstacle(
                        lane: lane,
                        isLog: true,
                        x: CGFloat.random(in: 0.1...0.9),
                        width: CGFloat.random(in: 0.16...0.24),
                        speed: (lane % 2 == 0 ? 1 : -1) * CGFloat.random(in: 0.12...0.22)
                    )
                )
            }
        }
        for lane in 7...10 {
            for _ in 0..<3 {
                froggerObstacles.append(
                    FroggerObstacle(
                        lane: lane,
                        isLog: false,
                        x: CGFloat.random(in: 0.1...0.9),
                        width: CGFloat.random(in: 0.10...0.18),
                        speed: (lane % 2 == 0 ? 1 : -1) * CGFloat.random(in: 0.16...0.28)
                    )
                )
            }
        }
    }

    func updateFroggerFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.frogger), froggerRunning, froggerGameOver == false else { return }

        for index in froggerObstacles.indices {
            froggerObstacles[index].x += froggerObstacles[index].speed * dt
            if froggerObstacles[index].x < -0.25 {
                froggerObstacles[index].x = 1.25
            } else if froggerObstacles[index].x > 1.25 {
                froggerObstacles[index].x = -0.25
            }
        }

        let playerX = (CGFloat(froggerPlayerCol) + 0.5) / CGFloat(froggerCols)
        let inWaterLane = froggerPlayerRow >= 2 && froggerPlayerRow <= 5
        let inRoadLane = froggerPlayerRow >= 7 && froggerPlayerRow <= 10

        if inRoadLane {
            for obstacle in froggerObstacles where obstacle.isLog == false && obstacle.lane == froggerPlayerRow {
                let half = obstacle.width * 0.5
                if playerX >= obstacle.x - half, playerX <= obstacle.x + half {
                    froggerRunning = false
                    froggerGameOver = true
                    triggerFlash()
                    return
                }
            }
        } else if inWaterLane {
            var onLog = false
            for obstacle in froggerObstacles where obstacle.isLog && obstacle.lane == froggerPlayerRow {
                let half = obstacle.width * 0.5
                if playerX >= obstacle.x - half, playerX <= obstacle.x + half {
                    onLog = true
                    froggerCarryAccumulator += obstacle.speed * dt * CGFloat(froggerCols)
                    let carryStep = Int(froggerCarryAccumulator.rounded(.towardZero))
                    if carryStep != 0 {
                        let nextCol = froggerPlayerCol + carryStep
                        froggerCarryAccumulator -= CGFloat(carryStep)
                        if nextCol < 0 || nextCol >= froggerCols {
                            froggerRunning = false
                            froggerGameOver = true
                            triggerFlash()
                            return
                        }
                        froggerPlayerCol = nextCol
                    }
                    break
                }
            }
            if onLog == false {
                froggerCarryAccumulator = 0
                froggerRunning = false
                froggerGameOver = true
                triggerFlash()
                return
            }
        } else {
            froggerCarryAccumulator = 0
        }

        if froggerPlayerRow == 0 {
            froggerScore += 200
            froggerPlayerCol = froggerCols / 2
            froggerPlayerRow = froggerRows - 1
            froggerCarryAccumulator = 0
            triggerFlash()
        }
    }

    var artilleryView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width * 0.94
            let height = geometry.size.height
            let cannonBase = CGPoint(x: width * artilleryCannonBase.x, y: height * artilleryCannonBase.y)
            let cannonLength = min(width, height) * 0.085
            let angleRad = artilleryAngleDeg * .pi / 180
            let cannonDirectionX: CGFloat = artilleryCannonFacing >= 0 ? 1 : -1

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.45), lineWidth: 1)
                    )

                Rectangle()
                    .fill(phosphorColor.opacity(0.18))
                    .frame(height: 2)
                    .position(x: width * 0.5, y: height * 0.88)

                ForEach(artilleryMountains) { mountain in
                    Path { path in
                        path.move(to: CGPoint(x: width * mountain.leftX, y: height * 0.88))
                        path.addLine(to: CGPoint(x: width * mountain.peakX, y: height * mountain.peakY))
                        path.addLine(to: CGPoint(x: width * mountain.rightX, y: height * 0.88))
                        path.closeSubpath()
                    }
                    .fill(phosphorColor.opacity(0.35))
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: width * mountain.leftX, y: height * 0.88))
                            path.addLine(to: CGPoint(x: width * mountain.peakX, y: height * mountain.peakY))
                            path.addLine(to: CGPoint(x: width * mountain.rightX, y: height * 0.88))
                        }
                        .stroke(phosphorColor.opacity(0.75), lineWidth: 1)
                    )
                }

                Circle()
                    .stroke(phosphorColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .position(cannonBase)

                Path { path in
                    path.move(to: cannonBase)
                    path.addLine(to: CGPoint(
                        x: cannonBase.x + cannonDirectionX * cos(angleRad) * cannonLength,
                        y: cannonBase.y - sin(angleRad) * cannonLength
                    ))
                }
                .stroke(phosphorColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))

                if artilleryTrail.count > 1 {
                    Path { path in
                        let start = artilleryTrail[0]
                        path.move(to: CGPoint(x: width * start.x, y: height * start.y))
                        for point in artilleryTrail.dropFirst() {
                            path.addLine(to: CGPoint(x: width * point.x, y: height * point.y))
                        }
                    }
                    .stroke(phosphorColor.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }

                Circle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: 16, height: 16)
                    .position(x: width * artilleryTarget.x, y: height * artilleryTarget.y)

                if artilleryProjectileActive {
                    Circle()
                        .fill(phosphorColor)
                        .frame(width: 6, height: 6)
                        .position(x: width * artilleryProjectileX, y: height * artilleryProjectileY)
                }

                VStack(spacing: 4) {
                    Text("ARTILLERY  \(artilleryScore)")
                        .font(displayFont(size: max(18, height * 0.08), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                    Text("ANG \(Int(artilleryAngleDeg))°")
                        .font(.system(size: max(11, height * 0.045), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                        .monospacedDigit()
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Text(artillerySpeedInput)
                    .font(displayFont(size: max(34, height * 0.16), weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 22)
                    .padding(.top, 46)

                Text(artilleryWindEnabled ? "WIND \(artilleryWindX >= 0 ? "→" : "←") \(Int((abs(artilleryWindX) * 100).rounded()))" : "WIND OFF")
                    .font(.system(size: max(11, height * 0.045), weight: .semibold, design: .monospaced))
                    .foregroundStyle(artilleryWindEnabled ? phosphorColor : phosphorDim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 20)
                    .padding(.top, 52)
                    .monospacedDigit()

                Text("numeros=velocidad · rueda ajusta · puntero apunta · enter=disparo · backspace borra")
                    .font(.system(size: max(10, height * 0.040), weight: .regular, design: .monospaced))
                    .foregroundStyle(phosphorDim.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .overlay(
                MouseClickCatcher(
                    onLeftClick: { fireArtilleryShot() },
                    onRightClick: { resetArtilleryGame() },
                    onScroll: { deltaY in
                        artilleryAdjustSpeedWithScroll(deltaY)
                    }
                )
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let dx = location.x - cannonBase.x
                    let dy = location.y - cannonBase.y
                    let alignedDx = dx * cannonDirectionX
                    guard alignedDx > 0.001 else { return }
                    let angle = atan2(-dy, alignedDx) * 180 / .pi
                    artilleryAngleDeg = max(8, min(84, angle))
                case .ended:
                    break
                }
            }
        }
    }

    func activateArtilleryMode() {
        if artilleryMountains.isEmpty {
            resetArtilleryGame()
        }
        installArtilleryKeyboardMonitorIfNeeded()
        startArtilleryTimerIfNeeded()
    }

    func deactivateArtilleryMode() {
        artilleryTimer?.setEventHandler {}
        artilleryTimer?.cancel()
        artilleryTimer = nil
        if let monitor = artilleryKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            artilleryKeyboardMonitor = nil
        }
    }

    func installArtilleryKeyboardMonitorIfNeeded() {
        guard artilleryKeyboardMonitor == nil else { return }
        artilleryKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isGameActive(.artillery) else { return event }
            switch event.keyCode {
            case 36:
                fireArtilleryShot()
                return nil
            case 51:
                if artillerySpeedInput.isEmpty == false {
                    artillerySpeedInput.removeLast()
                    if artillerySpeedInput.isEmpty {
                        artillerySpeedInput = "0"
                    }
                }
                return nil
            case 15:
                resetArtilleryGame()
                return nil
            default:
                if let chars = event.charactersIgnoringModifiers,
                   chars.count == 1,
                   let scalar = chars.unicodeScalars.first,
                   CharacterSet.decimalDigits.contains(scalar) {
                    if artillerySpeedInput == "0" {
                        artillerySpeedInput = String(chars)
                    } else if artillerySpeedInput.count < 3 {
                        artillerySpeedInput.append(chars)
                    }
                    return nil
                }
                return event
            }
        }
    }

    func startArtilleryTimerIfNeeded() {
        guard artilleryTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        let artilleryTickMs = 20
        timer.schedule(deadline: .now(), repeating: .milliseconds(artilleryTickMs), leeway: .milliseconds(6))
        timer.setEventHandler {
            updateArtilleryFrame(deltaTime: CGFloat(Double(artilleryTickMs) / 1000))
        }
        timer.resume()
        artilleryTimer = timer
    }

    func resetArtilleryGame() {
        artilleryRunning = false
        artilleryScore = 0
        artilleryAngleDeg = 44
        artillerySpeedInput = "62"
        artilleryProjectileActive = false
        artilleryProjectileX = artilleryCannonBase.x
        artilleryProjectileY = artilleryCannonBase.y
        artilleryProjectileVX = 0
        artilleryProjectileVY = 0
        artilleryTrail = []
        randomizeArtilleryRound()
    }

    func randomizeArtilleryWind() {
        guard artilleryWindEnabled else {
            artilleryWindX = 0
            return
        }
        var wind = CGFloat.random(in: -0.70...0.70)
        if abs(wind) < 0.08 {
            wind = wind >= 0 ? 0.08 : -0.08
        }
        artilleryWindX = wind
    }

    func randomizeArtilleryRound() {
        let cannonOnRight = Bool.random()
        artilleryCannonFacing = cannonOnRight ? -1 : 1
        artilleryCannonBase = CGPoint(
            x: cannonOnRight ? CGFloat.random(in: 0.74...0.90) : CGFloat.random(in: 0.10...0.26),
            y: CGFloat.random(in: 0.72...0.89)
        )

        var nextTargetX = CGFloat.random(in: 0.10...0.90)
        let minimumSeparation = CGFloat.random(in: 0.22...0.58)
        var guardCount = 0
        while abs(nextTargetX - artilleryCannonBase.x) < minimumSeparation, guardCount < 16 {
            nextTargetX = CGFloat.random(in: 0.10...0.90)
            guardCount += 1
        }
        artilleryTarget = CGPoint(
            x: nextTargetX,
            y: CGFloat.random(in: 0.30...0.82)
        )

        artilleryAngleDeg = CGFloat.random(in: 28...58)
        artilleryProjectileActive = false
        artilleryProjectileX = artilleryCannonBase.x
        artilleryProjectileY = artilleryCannonBase.y
        artilleryProjectileVX = 0
        artilleryProjectileVY = 0
        artilleryTrail = []

        randomizeArtilleryWind()
        artilleryMountains = generateArtilleryMountains(avoidXs: [artilleryCannonBase.x, artilleryTarget.x])
    }

    func generateArtilleryMountains(avoidXs: [CGFloat]) -> [ArtilleryMountain] {
        var mountains: [ArtilleryMountain] = []
        for _ in 0..<Int.random(in: 2...4) {
            var peakX = CGFloat.random(in: 0.16...0.86)
            var guardCount = 0
            while avoidXs.contains(where: { abs(peakX - $0) < 0.12 }), guardCount < 10 {
                peakX = CGFloat.random(in: 0.16...0.86)
                guardCount += 1
            }
            let halfBase = CGFloat.random(in: 0.05...0.11)
            mountains.append(
                ArtilleryMountain(
                    leftX: max(0.06, peakX - halfBase),
                    rightX: min(0.94, peakX + halfBase),
                    peakX: peakX,
                    peakY: CGFloat.random(in: 0.50...0.80)
                )
            )
        }
        return mountains.sorted { $0.peakX < $1.peakX }
    }

    func fireArtilleryShot() {
        if artilleryProjectileActive { return }
        let speedRaw = CGFloat(Double(artillerySpeedInput) ?? 62)
        let speed = max(0, min(100, speedRaw))
        let angleRad = artilleryAngleDeg * .pi / 180
        let normalized = speed / 100
        let power = pow(normalized, 0.92)
        let muzzleOffset: CGFloat = 0.026
        let launchSpeed: CGFloat = 0.30 + power * 1.55

        artilleryProjectileX = artilleryCannonBase.x + artilleryCannonFacing * cos(angleRad) * muzzleOffset
        artilleryProjectileY = artilleryCannonBase.y - sin(angleRad) * muzzleOffset
        artilleryProjectileVX = artilleryCannonFacing * cos(angleRad) * launchSpeed
        artilleryProjectileVY = -sin(angleRad) * launchSpeed
        artilleryProjectileActive = true
        artilleryRunning = true
        artilleryTrail = [CGPoint(x: artilleryProjectileX, y: artilleryProjectileY)]
    }

    func artilleryAdjustSpeedWithScroll(_ deltaY: CGFloat) {
        let current = max(0, min(100, Int(artillerySpeedInput) ?? 50))
        let normalizedDelta = -deltaY
        var step = Int(round(normalizedDelta / 8.5))
        if step == 0, abs(normalizedDelta) > 0.001 {
            step = normalizedDelta > 0 ? 1 : -1
        }
        step = max(-2, min(2, step))
        let next = max(0, min(100, current + step))
        artillerySpeedInput = "\(next)"
    }

    func updateArtilleryFrame(deltaTime dt: CGFloat) {
        guard isGameActive(.artillery), artilleryRunning, artilleryProjectileActive else { return }

        if artilleryWindEnabled {
            artilleryProjectileVX += artilleryWindX * dt * 0.55
        }
        let gravityBase: CGFloat = 1.08
        let fallingBoost = min(1.20, max(0, artilleryProjectileVY) * 0.85)
        artilleryProjectileVY += (gravityBase + fallingBoost) * dt
        artilleryProjectileVX *= max(0.90, 1 - (0.045 * dt))

        artilleryProjectileX += artilleryProjectileVX * dt
        artilleryProjectileY += artilleryProjectileVY * dt
        artilleryTrail.append(CGPoint(x: artilleryProjectileX, y: artilleryProjectileY))
        if artilleryTrail.count > 340 {
            artilleryTrail.removeFirst(artilleryTrail.count - 340)
        }

        let dx = artilleryProjectileX - artilleryTarget.x
        let dy = artilleryProjectileY - artilleryTarget.y
        if (dx * dx + dy * dy) <= 0.0010 {
            artilleryScore += 100
            artilleryProjectileActive = false
            randomizeArtilleryRound()
            triggerFlash()
            return
        }

        for mountain in artilleryMountains {
            if artilleryPointInMountain(CGPoint(x: artilleryProjectileX, y: artilleryProjectileY), mountain: mountain) {
                artilleryProjectileActive = false
                return
            }
        }

        if artilleryProjectileX < 0 || artilleryProjectileX > 1 || artilleryProjectileY < 0 || artilleryProjectileY > 1 {
            artilleryProjectileActive = false
        }
    }

    func artilleryPointInMountain(_ point: CGPoint, mountain: ArtilleryMountain) -> Bool {
        let a = CGPoint(x: mountain.leftX, y: 0.88)
        let b = CGPoint(x: mountain.peakX, y: mountain.peakY)
        let c = CGPoint(x: mountain.rightX, y: 0.88)
        let area = abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y))
        if area <= 0.00001 { return false }
        let s = abs((a.y * c.x - a.x * c.y) + (c.y - a.y) * point.x + (a.x - c.x) * point.y) / area
        let t = abs((a.x * b.y - a.y * b.x) + (a.y - b.y) * point.x + (b.x - a.x) * point.y) / area
        return s >= 0 && t >= 0 && (s + t) <= 1
    }


}
