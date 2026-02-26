import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

extension ContentView {
    #if os(macOS)
    var teleprompterView: some View {
        ZStack {
            if teleprompterFullscreen {
                // Vista a pantalla completa
                teleprompterFullscreenView
            } else {
                // Vista normal con controles
                teleprompterNormalView
            }
        }
    }
    
    var teleprompterNormalView: some View {
        VStack(spacing: 0) {
            // Espaciador para evitar solapamiento con el título del modo
            Color.clear
                .frame(height: 50)
            
            // Barra de controles superior
            VStack(spacing: 12) {
                // Primera fila: Cargar archivo y nombre
                HStack(spacing: 16) {
                    Button(action: {
                        loadTeleprompterFile()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 18, weight: .medium))
                            Text(L10n.teleprompterLoadFile)
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(phosphorColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(phosphorColor.opacity(0.45), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if teleprompterLoadedFileName.isEmpty == false {
                        Text(teleprompterLoadedFileName)
                            .font(.system(size: 16, weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                // Segunda fila: Controles de reproducción
                HStack(spacing: 20) {
                    // Control de velocidad
                    HStack(spacing: 12) {
                        Text(L10n.teleprompterSpeed)
                            .font(.system(size: 17, weight: .medium, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        
                        Button(action: {
                            decreaseTeleprompterSpeed()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(phosphorColor)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("z", modifiers: [])
                        
                        Text("\(Int(teleprompterSpeed))")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                            .monospacedDigit()
                            .frame(minWidth: 50)
                        
                        Button(action: {
                            increaseTeleprompterSpeed()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(phosphorColor)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("a", modifiers: [])
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.35), lineWidth: 1.5)
                    )
                    
                    // Botón Play/Pause
                    Button(action: {
                        toggleTeleprompterPlayback()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: teleprompterIsPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .medium))
                            Text(teleprompterIsPlaying ? L10n.teleprompterPause : L10n.teleprompterPlay)
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(phosphorColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(phosphorColor.opacity(0.55), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    
                    // Botón Reset
                    Button(action: {
                        resetTeleprompterScroll()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .medium))
                            Text(L10n.reset)
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(phosphorDim)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(phosphorDim.opacity(0.35), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Botón Fullscreen
                    Button(action: {
                        toggleTeleprompterFullscreen()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(phosphorColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.35))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.45), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.45))
            
            // Área de texto con scroll
            teleprompterScrollView(fontSize: 32, padding: 50)
        }
    }
    
    var teleprompterFullscreenView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Área de texto con scroll (más grande en fullscreen)
                teleprompterScrollView(fontSize: 48, padding: 80)
            }
            
            // Controles mínimos en overlay
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        toggleTeleprompterFullscreen()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(phosphorColor.opacity(0.8))
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 80)  // Más margen a la derecha para evitar solapamiento
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Controles inferiores
                HStack(spacing: 24) {
                    Button(action: {
                        decreaseTeleprompterSpeed()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(phosphorColor.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("z", modifiers: [])
                    
                    Button(action: {
                        toggleTeleprompterPlayback()
                    }) {
                        Image(systemName: teleprompterIsPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(phosphorColor)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.space, modifiers: [])
                    
                    Button(action: {
                        increaseTeleprompterSpeed()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(phosphorColor.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("a", modifiers: [])
                    
                    Button(action: {
                        resetTeleprompterScroll()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(phosphorDim.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.bottom, 30)
            }
        }
    }
    
    func teleprompterScrollView(fontSize: CGFloat, padding: CGFloat) -> some View {
        TeleprompterScrollView(
            attributedString: teleprompterText,
            fontSize: fontSize,
            textColor: NSColor(phosphorColor),
            padding: padding,
            scrollOffset: teleprompterScrollOffset
        )
    }
    
    // MARK: - Actions
    
    func loadTeleprompterFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText, .rtf, .text]
        panel.message = "Selecciona un archivo de texto (.txt) o RTF"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            loadTeleprompterContent(from: url)
        }
    }
    
    func loadTeleprompterContent(from url: URL) {
        do {
            if url.pathExtension.lowercased() == "rtf" {
                // Cargar RTF con formato
                let attributedString = try NSAttributedString(
                    url: url,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                teleprompterText = attributedString
            } else {
                // Cargar texto plano
                let plainText = try String(contentsOf: url, encoding: .utf8)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 28, weight: .regular),
                    .foregroundColor: NSColor(phosphorColor)
                ]
                teleprompterText = NSAttributedString(string: plainText, attributes: attributes)
            }
            
            teleprompterLoadedFileName = url.lastPathComponent
            resetTeleprompterScroll()
        } catch {
            print("Error loading teleprompter file: \(error)")
        }
    }
    
    func toggleTeleprompterPlayback() {
        teleprompterIsPlaying.toggle()
        
        if teleprompterIsPlaying {
            startTeleprompterScroll()
        } else {
            stopTeleprompterScroll()
        }
    }
    
    func startTeleprompterScroll() {
        guard teleprompterTimer == nil else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard teleprompterIsPlaying else { return }
            teleprompterScrollOffset += teleprompterSpeed / 60.0
        }
        
        RunLoop.main.add(timer, forMode: .common)
        teleprompterTimer = timer
    }
    
    func stopTeleprompterScroll() {
        teleprompterTimer?.invalidate()
        teleprompterTimer = nil
    }
    
    func resetTeleprompterScroll() {
        teleprompterIsPlaying = false
        stopTeleprompterScroll()
        teleprompterScrollOffset = 0
    }
    
    func increaseTeleprompterSpeed() {
        teleprompterSpeed = min(200, teleprompterSpeed + 5)
    }
    
    func decreaseTeleprompterSpeed() {
        teleprompterSpeed = max(5, teleprompterSpeed - 5)
    }
    
    func toggleTeleprompterFullscreen() {
        teleprompterFullscreen.toggle()
    }
    
    func deactivateTeleprompterMode() {
        stopTeleprompterScroll()
        teleprompterIsPlaying = false
        teleprompterFullscreen = false
    }
    #endif
}

// MARK: - TeleprompterScrollView

#if os(macOS)
struct TeleprompterScrollView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let fontSize: CGFloat
    let textColor: NSColor
    let padding: CGFloat
    let scrollOffset: CGFloat
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: padding, height: 150)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Actualizar el contenido solo si cambió
        if attributedString.length > 0 {
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            let fullRange = NSRange(location: 0, length: mutableString.length)
            
            // Escalar las fuentes al tamaño deseado
            mutableString.enumerateAttribute(.font, in: fullRange) { value, range, _ in
                if let currentFont = value as? NSFont {
                    let scaledFont = NSFont(
                        descriptor: currentFont.fontDescriptor,
                        size: fontSize
                    ) ?? NSFont.systemFont(ofSize: fontSize)
                    mutableString.addAttribute(.font, value: scaledFont, range: range)
                } else {
                    mutableString.addAttribute(.font, value: NSFont.systemFont(ofSize: fontSize), range: range)
                }
            }
            
            // Aplicar color si no hay color definido
            mutableString.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
                if value == nil {
                    mutableString.addAttribute(.foregroundColor, value: textColor, range: range)
                }
            }
            
            // Ajustar interlineado y alineación
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = fontSize * 0.5
            paragraphStyle.alignment = .center
            mutableString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
            
            if textView.textStorage?.string != mutableString.string {
                textView.textStorage?.setAttributedString(mutableString)
            }
        } else {
            // Mostrar mensaje cuando no hay archivo
            let noFileText = "Sin archivo cargado / No file loaded"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize * 0.6, weight: .medium),
                .foregroundColor: textColor.withAlphaComponent(0.5)
            ]
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrString = NSMutableAttributedString(string: noFileText, attributes: attributes)
            attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: noFileText.count))
            
            textView.textStorage?.setAttributedString(attrString)
        }
        
        // Aplicar scroll suavemente
        let contentView = scrollView.contentView
        var newOrigin = contentView.bounds.origin
        newOrigin.y = scrollOffset
        
        // Asegurar que no se salga de los límites
        let maxY = max(0, (textView.bounds.height + 150) - contentView.bounds.height)
        newOrigin.y = min(max(0, newOrigin.y), maxY)
        
        contentView.scroll(to: newOrigin)
    }
}

// MARK: - AttributedTextView (deprecated, kept for compatibility)

struct AttributedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let fontSize: CGFloat
    let textColor: NSColor
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        // Aplicar el tamaño de fuente y color al texto atribuido
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        
        // Escalar las fuentes existentes al tamaño deseado
        mutableString.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            if let currentFont = value as? NSFont {
                let scaledFont = NSFont(
                    descriptor: currentFont.fontDescriptor,
                    size: fontSize
                ) ?? NSFont.systemFont(ofSize: fontSize)
                mutableString.addAttribute(.font, value: scaledFont, range: range)
            } else {
                mutableString.addAttribute(.font, value: NSFont.systemFont(ofSize: fontSize), range: range)
            }
        }
        
        // Aplicar color si no hay color definido
        mutableString.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
            if value == nil {
                mutableString.addAttribute(.foregroundColor, value: textColor, range: range)
            }
        }
        
        // Ajustar interlineado para mejor legibilidad
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = fontSize * 0.4
        paragraphStyle.alignment = .center
        mutableString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        nsView.textStorage?.setAttributedString(mutableString)
    }
}
#endif

