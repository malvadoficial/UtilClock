import SwiftUI
#if os(macOS)
import AppKit
#endif

extension ContentView {
    @ViewBuilder
    func audioUtilityView(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text(L10n.selectedAudio)
                    .font(.system(size: max(16, dateSize * 1.2), weight: .medium, design: .monospaced))
                    .foregroundStyle(phosphorDim)

                Text(selectedAudioDeviceName)
                    .font(displayFont(size: max(22, driveTitleSize * 1.2), weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                    .padding(.horizontal, 18)
            }

            VStack(spacing: 8) {
                Text(L10n.systemVolume)
                    .font(.system(size: max(15, dateSize * 1.1), weight: .medium, design: .monospaced))
                    .foregroundStyle(phosphorDim)

                if systemVolumePercent <= 0.0001 {
                    Text("MUTED")
                        .font(displayFont(size: max(24, driveTitleSize * 1.28), weight: .bold))
                        .foregroundStyle(Color.red)
                        .monospacedDigit()
                        .shadow(color: Color.red.opacity(0.55), radius: 6)
                } else {
                    Text(String(format: "%.0f%%", systemVolumePercent))
                        .font(displayFont(size: max(24, driveTitleSize * 1.28), weight: .bold))
                        .foregroundStyle(phosphorColor)
                        .monospacedDigit()
                        .shadow(color: phosphorColor.opacity(0.7), radius: 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    func cpuUtilityView(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        VStack(spacing: 14) {
            Text(L10n.cpuUsage)
                .font(.system(size: max(16, dateSize * 1.2), weight: .medium, design: .monospaced))
                .foregroundStyle(phosphorDim)

            Text(String(format: "%.1f%%", cpuUsagePercent))
                .font(displayFont(size: max(28, driveTitleSize * 1.5), weight: .bold))
                .foregroundStyle(phosphorColor)
                .monospacedDigit()
                .shadow(color: phosphorColor.opacity(0.7), radius: 6)

            Text(memoryUsageText)
                .font(displayFont(size: max(20, driveTitleSize * 1.05), weight: .regular))
                .foregroundStyle(phosphorDim)
                .monospacedDigit()
                .shadow(color: phosphorColor.opacity(0.45), radius: 4)
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 64)
    }

    @ViewBuilder
    func appsUtilityView(dateSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                appsMonitorToggleButton(title: L10n.modeApps, mode: .apps)
                appsMonitorToggleButton(title: L10n.modeProcesses, mode: .processes)
            }
            .padding(.top, 0)

            if selectedAppsMonitorMode == .apps {
                if runningAppsUsage.isEmpty {
                    Text(L10n.noRunningAppsCPUData)
                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(runningAppsUsage) { app in
                                HStack(spacing: 10) {
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .interpolation(.high)
                                        .frame(width: max(16, dateSize * 1.05), height: max(16, dateSize * 1.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                                    Text(app.name)
                                        .font(.system(size: max(13, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .lineLimit(1)
                                        .truncationMode(.tail)

                                    Spacer(minLength: 8)

                                    Text(String(format: "%.1f%%", app.cpuPercent))
                                        .font(.system(size: max(13, dateSize * 0.95), weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                if runningProcessesUsage.isEmpty {
                    Text(L10n.noRunningProcessesCPUData)
                        .font(.system(size: max(14, dateSize * 0.95), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(runningProcessesUsage) { process in
                                HStack(spacing: 10) {
                                    Text("\(process.id)")
                                        .font(.system(size: max(12, dateSize * 0.85), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .monospacedDigit()
                                        .frame(width: max(72, dateSize * 4.1), alignment: .leading)
                                        .lineLimit(1)

                                    Text(process.name)
                                        .font(.system(size: max(13, dateSize * 0.95), weight: .regular, design: .monospaced))
                                        .foregroundStyle(phosphorColor)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer(minLength: 8)

                                    Text(String(format: "%.1f%%", process.cpuPercent))
                                        .font(.system(size: max(13, dateSize * 0.95), weight: .semibold, design: .monospaced))
                                        .foregroundStyle(phosphorDim)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 18)
    }

    @ViewBuilder
    func networkUtilityView(dateSize: CGFloat, driveTitleSize: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(L10n.networkWiFi) (\(networkWiFiInterfaceName))")
                        .font(.system(size: max(13, dateSize * 0.9), weight: .medium, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                    HStack(spacing: 14) {
                        Text("↓ \(L10n.networkDownload): \(formattedNetworkSpeed(networkWiFiDownloadBytesPerSecond))")
                        Text("↑ \(L10n.networkUpload): \(formattedNetworkSpeed(networkWiFiUploadBytesPerSecond))")
                    }
                    .font(.system(size: max(18, driveTitleSize * 0.82), weight: .semibold, design: .monospaced))
                    .foregroundStyle(phosphorColor)
                    .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(L10n.networkEthernet) (\(networkEthernetInterfaceName))")
                        .font(.system(size: max(13, dateSize * 0.9), weight: .medium, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                    HStack(spacing: 14) {
                        Text("↓ \(L10n.networkDownload): \(formattedNetworkSpeed(networkEthernetDownloadBytesPerSecond))")
                        Text("↑ \(L10n.networkUpload): \(formattedNetworkSpeed(networkEthernetUploadBytesPerSecond))")
                    }
                    .font(.system(size: max(18, driveTitleSize * 0.82), weight: .semibold, design: .monospaced))
                    .foregroundStyle(phosphorColor)
                    .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.networkPublicIP)
                        .font(.system(size: max(14, dateSize * 0.95), weight: .medium, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                    Text(networkPublicIPAddress)
                        .font(.system(size: max(26, driveTitleSize * 1.12), weight: .bold, design: .monospaced))
                        .foregroundStyle(phosphorColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(L10n.networkPrivateIP) \(L10n.networkWiFi)")
                        .font(.system(size: max(14, dateSize * 0.95), weight: .medium, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                    Text(networkWiFiPrivateIPAddress)
                        .font(.system(size: max(26, driveTitleSize * 1.12), weight: .bold, design: .monospaced))
                        .foregroundStyle(phosphorColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(L10n.networkPrivateIP) \(L10n.networkEthernet)")
                        .font(.system(size: max(14, dateSize * 0.95), weight: .medium, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                    Text(networkEthernetPrivateIPAddress)
                        .font(.system(size: max(26, driveTitleSize * 1.12), weight: .bold, design: .monospaced))
                        .foregroundStyle(phosphorColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 76)
        .padding(.leading, 44)
        .padding(.trailing, 12)
    }

    @ViewBuilder
    func storageUtilityView(rowFontSize: CGFloat) -> some View {
        unifiedStorageAndUSBList(
            unifiedStorageAndUSBVolumes,
            rowFontSize: rowFontSize,
            topInset: 56
        )
    }
}
