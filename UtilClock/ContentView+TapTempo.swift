import SwiftUI
#if os(macOS)
import AVFoundation
#endif

extension ContentView {
    #if os(macOS)
    func registerTapTempoTap() {
        let now = Date()
        
        // Cancelar el timer de reset existente
        tapTempoResetTimer?.invalidate()
        tapTempoResetTimer = nil
        
        // Añadir el tap actual
        tapTempoTaps.append(now)
        
        // Activar el efecto visual del pulso
        tapTempoPulseActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tapTempoPulseActive = false
        }
        
        // Reproducir sonido
        playTapTempoSound()
        
        // Mantener solo los últimos 8 taps (para un cálculo más preciso)
        if tapTempoTaps.count > 8 {
            tapTempoTaps.removeFirst()
        }
        
        // Calcular BPM si tenemos al menos 2 taps
        if tapTempoTaps.count >= 2 {
            calculateTapTempoBPM()
        }
        
        // Programar reset automático después de 3 segundos de inactividad
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak tapTempoResetTimer] _ in
            guard tapTempoResetTimer != nil else { return }
            resetTapTempo()
        }
        RunLoop.main.add(timer, forMode: .common)
        tapTempoResetTimer = timer
    }
    
    func calculateTapTempoBPM() {
        guard tapTempoTaps.count >= 2 else {
            tapTempoBPM = 0
            return
        }
        
        // Calcular intervalos entre taps consecutivos
        var intervals: [TimeInterval] = []
        for i in 1..<tapTempoTaps.count {
            let interval = tapTempoTaps[i].timeIntervalSince(tapTempoTaps[i - 1])
            intervals.append(interval)
        }
        
        // Calcular el promedio de los intervalos
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        // Convertir a BPM (60 segundos / intervalo promedio)
        guard averageInterval > 0 else {
            tapTempoBPM = 0
            return
        }
        
        let bpm = 60.0 / averageInterval
        
        // Limitar el BPM a un rango razonable (20-300)
        tapTempoBPM = max(20, min(300, bpm))
    }
    
    func resetTapTempo() {
        tapTempoResetTimer?.invalidate()
        tapTempoResetTimer = nil
        tapTempoTaps.removeAll()
        tapTempoBPM = 0
        tapTempoPulseActive = false
    }
    
    func playTapTempoSound() {
        // Reutilizar el sonido del metrónomo si está disponible
        if metronomeStrongTickPlayer == nil {
            prepareMetronomeTickPlayersIfNeeded()
        }
        
        if let player = metronomeStrongTickPlayer {
            player.currentTime = 0
            player.play()
        } else if let fallback = NSSound(named: "Pop") {
            fallback.play()
        } else {
            NSSound.beep()
        }
    }
    
    func deactivateTapTempoMode() {
        resetTapTempo()
    }
    #endif
}
