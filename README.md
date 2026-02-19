# UtilClock

UtilClock es una app para macOS con estética de monitor monocromo que combina reloj y utilidades en dos subpantallas.

## Características

- Subpantalla superior:
  - Reloj
  - Reloj mundial
  - Uptime
  - Cuenta atrás
  - Alarma
- Subpantalla inferior (modos configurables):
  - Audio / USB / Almacenamiento
  - CPU + memoria
  - Volumen
  - Metrónomo
  - Afinador
  - Detector de acordes
  - Buscador de acordes
  - Búsqueda de palabras en RAE
  - Tal día
  - Frase musical
  - Pong / Arkanoid / Snake / Missile Command
- Configuración integrada:
  - Activar/desactivar modos
  - Reordenar modos
  - Color del display
  - Ajustes de tamaño para juegos

## Requisitos

- macOS
- Xcode 15+

## Ejecutar en local

1. Abrir `UtilClock.xcodeproj` en Xcode.
2. Seleccionar el esquema `UtilClock`.
3. Ejecutar con `Run` sobre `My Mac`.

## Build desde terminal

```bash
xcodebuild -project UtilClock.xcodeproj -scheme UtilClock -configuration Debug -sdk macosx build
```

## Notas

- La app usa entrada de audio para afinador/detección de acordes.
- Algunas funciones pueden requerir permisos del sistema (micrófono, etc.).
