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
        GeometryReader { geometry in
            let wideLayout = geometry.size.width >= 760
            let labelFontSize = max(11, dateSize * 0.74)
            let valueFontSize = max(17, driveTitleSize * 0.72)
            let ipFontSize = max(18, driveTitleSize * 0.76)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    networkPublicIPPanel(
                        value: networkPublicIPAddress,
                        labelFontSize: labelFontSize,
                        valueFontSize: ipFontSize
                    )

                    HStack(alignment: .top, spacing: 8) {
                        networkInterfacePanel(
                            title: "\(L10n.networkWiFi) (\(networkWiFiInterfaceName))",
                            download: networkWiFiDownloadBytesPerSecond,
                            upload: networkWiFiUploadBytesPerSecond,
                            privateIP: networkWiFiPrivateIPAddress,
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            ipFontSize: ipFontSize
                        )

                        if wideLayout {
                            networkInterfacePanel(
                                title: "\(L10n.networkEthernet) (\(networkEthernetInterfaceName))",
                                download: networkEthernetDownloadBytesPerSecond,
                                upload: networkEthernetUploadBytesPerSecond,
                                privateIP: networkEthernetPrivateIPAddress,
                                labelFontSize: labelFontSize,
                                valueFontSize: valueFontSize,
                                ipFontSize: ipFontSize
                            )
                        }
                    }

                    if wideLayout == false {
                        networkInterfacePanel(
                            title: "\(L10n.networkEthernet) (\(networkEthernetInterfaceName))",
                            download: networkEthernetDownloadBytesPerSecond,
                            upload: networkEthernetUploadBytesPerSecond,
                            privateIP: networkEthernetPrivateIPAddress,
                            labelFontSize: labelFontSize,
                            valueFontSize: valueFontSize,
                            ipFontSize: ipFontSize
                        )
                    }
                }
                .padding(.top, 52)
                .padding(.leading, 26)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    func networkPublicIPPanel(
        value: String,
        labelFontSize: CGFloat,
        valueFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L10n.networkPublicIP)
                .font(.system(size: labelFontSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(phosphorDim)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(value)
                .font(displayFont(size: valueFontSize, weight: .bold))
                .foregroundStyle(phosphorColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.26))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(phosphorColor.opacity(0.22), lineWidth: 1)
        )
    }

    @ViewBuilder
    func networkInterfacePanel(
        title: String,
        download: Double,
        upload: Double,
        privateIP: String,
        labelFontSize: CGFloat,
        valueFontSize: CGFloat,
        ipFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: labelFontSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(phosphorDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                Text("↓ \(formattedNetworkSpeed(download))")
                    .font(displayFont(size: valueFontSize, weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
                    .monospacedDigit()
                Text("↑ \(formattedNetworkSpeed(upload))")
                    .font(displayFont(size: valueFontSize, weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.networkPrivateIP)
                    .font(.system(size: labelFontSize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(phosphorDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(privateIP)
                    .font(displayFont(size: ipFontSize, weight: .bold))
                    .foregroundStyle(phosphorColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.26))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(phosphorColor.opacity(0.22), lineWidth: 1)
        )
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
