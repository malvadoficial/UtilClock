import SwiftUI
#if os(macOS)
import AppKit
import Photos

extension ContentView {
    var photosClockColor: Color {
        let cycleSeconds = 900.0
        let t = Date().timeIntervalSinceReferenceDate
        let hue = (t.truncatingRemainder(dividingBy: cycleSeconds)) / cycleSeconds
        return Color(hue: hue, saturation: 0.22, brightness: 0.95)
    }

    var selectedPhotosSourceLabel: String {
        if photosSourceType == "album", photosSelectedAlbumName.isEmpty == false {
            return photosSelectedAlbumName
        }
        if photosSelectedFolderPath.isEmpty == false {
            return photosSelectedFolderPath
        }
        return "-"
    }

    @ViewBuilder
    func photosUtilityView(dateSize: CGFloat) -> some View {
        if photosIsRunning {
            photosPlaybackView(dateSize: dateSize)
        } else {
            photosLauncherView(dateSize: dateSize)
        }
    }

    @ViewBuilder
    func photosPlaybackView(dateSize: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                if let url = photosImageURLs[safe: photosCurrentIndex],
                   let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black
                }

                if photosShowClock {
                    VStack {
                        HStack {
                            Text(viewModel.hourMinuteText)
                                .font(displayFont(size: max(56, dateSize * 2.7), weight: .bold))
                                .foregroundStyle(photosClockColor)
                                .shadow(color: Color.black.opacity(0.55), radius: 7)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 38)
                        .padding(.leading, 24)
                        Spacer(minLength: 0)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                stopPhotosSlideshow()
                splitFullscreenTarget = .none
            }
        }
    }

    @ViewBuilder
    func photosLauncherView(dateSize: CGFloat) -> some View {
        GeometryReader { geometry in
            let colGap: CGFloat = 16
            let rightColWidth = max(280, min(360, geometry.size.width * 0.38))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: colGap) {
                    HStack(spacing: 10) {
                        Button(action: toggleAlbumsPanel) { Text("Album Fotos") }
                            .buttonStyle(photosSourceButtonStyle(active: photosShowAlbumsList))
                        Button(action: choosePhotosFolder) { Text("Carpeta") }
                            .buttonStyle(photosSourceButtonStyle(active: photosSourceType == "folder"))
                    }
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 10) {
                            Toggle(isOn: $photosShowClock) {
                                Text("Mostrar reloj")
                                    .font(.system(size: max(14, dateSize * 0.9), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                            }
                            .toggleStyle(.switch)
                            .onChange(of: photosShowClock) { _, _ in savePhotoModeSettings() }
                        }

                        HStack(spacing: 10) {
                            Text("Duracion")
                                .font(.system(size: max(14, dateSize * 0.92), weight: .regular, design: .monospaced))
                                .foregroundStyle(phosphorDim)

                            TextField("30", value: $photosSlideDurationSeconds, format: .number.precision(.fractionLength(0)))
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: max(14, dateSize * 0.92), weight: .regular, design: .monospaced))
                                .frame(width: 86)
                                .onChange(of: photosSlideDurationSeconds) { _, newValue in
                                    photosSlideDurationSeconds = max(1, min(3600, newValue))
                                    savePhotoModeSettings()
                                }
                            Text("s")
                                .font(.system(size: max(14, dateSize * 0.92), weight: .regular, design: .monospaced))
                                .foregroundStyle(phosphorDim)
                        }
                    }
                    .frame(width: rightColWidth, alignment: .trailing)
                }

                if photosPermissionStatus != "authorized" && photosPermissionStatus != "limited" {
                    HStack(spacing: 10) {
                        Text(photosPermissionHintText)
                            .font(.system(size: max(12, dateSize * 0.82), weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Button(action: requestPhotosPermissionFromUI) { Text("Pedir permiso") }
                            .buttonStyle(photosCapsuleButtonStyle(active: false))
                    }
                }

                HStack(alignment: .top, spacing: colGap) {
                    VStack(alignment: .leading, spacing: 6) {
                        if photosShowAlbumsList, photosPermissionStatus == "authorized" || photosPermissionStatus == "limited" {
                            if photosAlbums.isEmpty {
                                Text("Sin albumes")
                                    .font(.system(size: max(13, dateSize * 0.86), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                            } else {
                                ScrollView(showsIndicators: true) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(photosAlbums) { album in
                                            Button(action: { selectPhotosAlbum(album) }) {
                                                HStack(spacing: 10) {
                                                    Text("\(album.count)")
                                                        .font(.system(size: max(13, dateSize * 0.82), weight: .semibold, design: .monospaced))
                                                        .foregroundStyle(phosphorDim)
                                                        .frame(width: 40, alignment: .leading)
                                                    Text(album.title)
                                                        .font(.system(size: max(13, dateSize * 0.86), weight: .regular, design: .monospaced))
                                                        .foregroundStyle(phosphorColor)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(photosSelectedAlbumID == album.id ? 0.5 : 0.22))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .stroke(phosphorColor.opacity(photosSelectedAlbumID == album.id ? 0.55 : 0.22), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .frame(height: 170)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Text("Origen:")
                                    .font(.system(size: max(13, dateSize * 0.85), weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                                Text(selectedPhotosSourceLabel)
                                    .font(.system(size: max(13, dateSize * 0.84), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .frame(height: 30, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(phosphorColor.opacity(0.25), lineWidth: 1)
                    )

                    Color.clear
                        .frame(width: rightColWidth, height: 1)
                }

                HStack(alignment: .center, spacing: colGap) {
                    HStack(spacing: 8) {
                        Text("Fotos:")
                            .font(.system(size: max(13, dateSize * 0.85), weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Text("\(photosImageURLs.count)")
                            .font(.system(size: max(14, dateSize * 0.9), weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: startPhotosSlideshow) {
                        Text("START")
                            .font(displayFont(size: max(36, dateSize * 1.75), weight: .bold))
                            .foregroundStyle(phosphorColor)
                            .frame(width: rightColWidth, alignment: .center)
                            .padding(.vertical, 14)
                            .background(Color.black.opacity(0.48))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(phosphorColor.opacity(0.58), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(canStartPhotos == false)
                    .opacity(canStartPhotos ? 1.0 : 0.48)
                }

                if photosLoading {
                    Text("Cargando...")
                        .font(.system(size: max(12, dateSize * 0.8), weight: .regular, design: .monospaced))
                        .foregroundStyle(phosphorDim)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 54)
        .padding(.bottom, 10)
    }

    var canStartPhotos: Bool {
        if photosLoading { return false }
        if photosImageURLs.isEmpty == false { return true }
        if photosSourceType == "album" {
            return photosSelectedAlbumID.isEmpty == false
        }
        return photosSelectedFolderPath.isEmpty == false
    }

    func photosCapsuleButtonStyle(active: Bool) -> some PrimitiveButtonStyle {
        PhotosCapsuleButtonStyle(active: active, phosphorColor: phosphorColor)
    }

    func photosSourceButtonStyle(active: Bool) -> some PrimitiveButtonStyle {
        PhotosSourceButtonStyle(active: active, phosphorColor: phosphorColor)
    }

    var photosPermissionHintText: String {
        switch photosPermissionStatus {
        case "denied":
            return "Permiso no concedido: denied"
        case "restricted":
            return "Permiso restringido"
        case "limited":
            return "Permiso limitado"
        case "notDetermined":
            return "Falta permiso para leer albumes de Fotos"
        default:
            return "Permiso de Fotos desconocido"
        }
    }

    func refreshPhotosModeIfNeeded() {
        refreshPhotoLibraryAuthorizationState()
        if photosSourceType == "album" {
            loadPhotosAlbums()
            loadImagesFromSelectedPhotosAlbum()
        } else {
            loadImagesFromSelectedPhotosFolder()
        }
    }

    func refreshPhotoLibraryAuthorizationState() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photosPermissionStatus = mapPhotosAuthStatus(status)
    }

    func mapPhotosAuthStatus(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .limited: return "limited"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    func requestPhotosPermissionFromUI() {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    photosPermissionStatus = mapPhotosAuthStatus(status)
                    if status == .authorized || status == .limited {
                        loadPhotosAlbums()
                    }
                }
            }
            return
        }
        if current == .denied || current == .restricted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func toggleAlbumsPanel() {
        refreshPhotoLibraryAuthorizationState()
        if photosPermissionStatus != "authorized" && photosPermissionStatus != "limited" {
            requestPhotosPermissionFromUI()
            return
        }
        if photosAlbums.isEmpty {
            loadPhotosAlbums()
        }
        photosShowAlbumsList.toggle()
    }

    func loadPhotosAlbums() {
        guard photosPermissionStatus == "authorized" || photosPermissionStatus == "limited" else { return }

        var byID: [String: PhotosAlbum] = [:]
        let options = PHFetchOptions()

        let sources: [(PHAssetCollectionType, PHAssetCollectionSubtype)] = [
            (.album, .any),
            (.smartAlbum, .any)
        ]
        for source in sources {
            let fetch = PHAssetCollection.fetchAssetCollections(with: source.0, subtype: source.1, options: nil)
            fetch.enumerateObjects { collection, _, _ in
                let count = PHAsset.fetchAssets(in: collection, options: options).count
                guard count > 0 else { return }
                let title = collection.localizedTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Album"
                byID[collection.localIdentifier] = PhotosAlbum(
                    id: collection.localIdentifier,
                    title: title,
                    count: count
                )
            }
        }

        var result = Array(byID.values)
        result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        photosAlbums = result
    }

    func selectPhotosAlbum(_ album: PhotosAlbum) {
        photosSourceType = "album"
        photosSelectedAlbumID = album.id
        photosSelectedAlbumName = album.title
        photosShowAlbumsList = false
        savePhotoModeSettings()
        loadImagesFromSelectedPhotosAlbum()
    }

    func choosePhotosFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Seleccionar"
        if panel.runModal() == .OK, let url = panel.url {
            photosSourceType = "folder"
            photosSelectedFolderPath = url.path
            photosSelectedFolderBookmark = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            photosShowAlbumsList = false
            savePhotoModeSettings()
            loadImagesFromSelectedPhotosFolder()
        }
    }

    func loadImagesFromSelectedPhotosFolder() {
        guard photosSourceType == "folder" else { return }
        guard let folderURL = resolvePhotosFolderURL() else {
            photosImageURLs = []
            photosCurrentIndex = 0
            return
        }

        let didAccess = folderURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let urls = (try? fm.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )) ?? []

        photosImageURLs = urls.filter { url in
            let ext = url.pathExtension.lowercased()
            return ["jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tif", "tiff", "webp"].contains(ext)
        }
        .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

        photosCurrentIndex = 0
    }

    func loadImagesFromSelectedPhotosAlbum() {
        guard photosSourceType == "album", photosSelectedAlbumID.isEmpty == false else { return }
        guard photosPermissionStatus == "authorized" || photosPermissionStatus == "limited" else {
            photosImageURLs = []
            return
        }

        photosLoading = true
        let selectedID = photosSelectedAlbumID
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [selectedID], options: nil)
            guard let collection = fetchCollection.firstObject else {
                DispatchQueue.main.async {
                    photosLoading = false
                    photosImageURLs = []
                }
                return
            }
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            let manager = PHImageManager.default()
            let opts = PHImageRequestOptions()
            opts.isSynchronous = true
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .highQualityFormat
            opts.version = .current

            let cacheRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("utilclock-photo-cache", isDirectory: true)
            let albumDir = cacheRoot.appendingPathComponent(selectedID.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
            try? FileManager.default.createDirectory(at: albumDir, withIntermediateDirectories: true)

            var urls: [URL] = []
            assets.enumerateObjects { asset, index, _ in
                var requestURL: URL?
                manager.requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, _ in
                    guard let data else { return }
                    let out = albumDir.appendingPathComponent("\(index)-\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).jpg")
                    if (try? data.write(to: out, options: .atomic)) != nil {
                        requestURL = out
                    }
                }
                if let requestURL {
                    urls.append(requestURL)
                }
            }

            DispatchQueue.main.async {
                photosLoading = false
                photosImageURLs = urls
                photosCurrentIndex = 0
                if photosStartWhenReady {
                    beginPhotosSlideshowWithCurrentImages()
                }
            }
        }
    }

    func startPhotosSlideshow() {
        photosStartWhenReady = false
        if photosSourceType == "album" {
            if photosImageURLs.isEmpty {
                photosStartWhenReady = true
                loadImagesFromSelectedPhotosAlbum()
                return
            }
        } else {
            if photosImageURLs.isEmpty {
                loadImagesFromSelectedPhotosFolder()
            }
        }
        beginPhotosSlideshowWithCurrentImages()
    }

    func beginPhotosSlideshowWithCurrentImages() {
        guard photosImageURLs.isEmpty == false else {
            photosStartWhenReady = false
            return
        }

        photosCurrentIndex = Int.random(in: 0..<photosImageURLs.count)
        photosIsRunning = true
        splitFullscreenTarget = .bottom
        photosStartWhenReady = false
        restartPhotosTimer()
    }

    func restartPhotosTimer() {
        photosTimer?.invalidate()
        photosTimer = Timer.scheduledTimer(withTimeInterval: max(1.0, photosSlideDurationSeconds), repeats: true) { _ in
            DispatchQueue.main.async {
                guard photosImageURLs.isEmpty == false else { return }
                if photosImageURLs.count == 1 {
                    photosCurrentIndex = 0
                } else {
                    var next = photosCurrentIndex
                    while next == photosCurrentIndex {
                        next = Int.random(in: 0..<photosImageURLs.count)
                    }
                    photosCurrentIndex = next
                }
            }
        }
        if let photosTimer {
            RunLoop.main.add(photosTimer, forMode: .common)
        }
    }

    func stopPhotosSlideshow() {
        photosTimer?.invalidate()
        photosTimer = nil
        photosIsRunning = false
    }

    func savePhotoModeSettings() {
        let defaults = UserDefaults.standard
        defaults.set(photosSelectedFolderPath, forKey: "utilclock.photos.folderPath")
        defaults.set(photosSlideDurationSeconds, forKey: "utilclock.photos.slideDuration")
        defaults.set(photosShowClock, forKey: "utilclock.photos.showClock")
        defaults.set(photosSelectedFolderBookmark, forKey: "utilclock.photos.folderBookmark")
        defaults.set(photosSourceType, forKey: "utilclock.photos.sourceType")
        defaults.set(photosSelectedAlbumID, forKey: "utilclock.photos.albumID")
        defaults.set(photosSelectedAlbumName, forKey: "utilclock.photos.albumName")
    }

    func loadPhotoModeSettings() {
        let defaults = UserDefaults.standard
        photosSelectedFolderPath = defaults.string(forKey: "utilclock.photos.folderPath") ?? ""
        photosSlideDurationSeconds = max(1, defaults.double(forKey: "utilclock.photos.slideDuration"))
        if defaults.object(forKey: "utilclock.photos.slideDuration") == nil {
            photosSlideDurationSeconds = 30
        }
        photosShowClock = defaults.object(forKey: "utilclock.photos.showClock") as? Bool ?? true
        photosSelectedFolderBookmark = defaults.data(forKey: "utilclock.photos.folderBookmark")
        photosSourceType = defaults.string(forKey: "utilclock.photos.sourceType") ?? "folder"
        photosSelectedAlbumID = defaults.string(forKey: "utilclock.photos.albumID") ?? ""
        photosSelectedAlbumName = defaults.string(forKey: "utilclock.photos.albumName") ?? ""

        refreshPhotoLibraryAuthorizationState()
        if photosSourceType == "album" {
            loadPhotosAlbums()
            loadImagesFromSelectedPhotosAlbum()
        } else {
            loadImagesFromSelectedPhotosFolder()
        }
    }

    func resolvePhotosFolderURL() -> URL? {
        if let bookmark = photosSelectedFolderBookmark {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale {
                    photosSelectedFolderBookmark = try? url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    savePhotoModeSettings()
                }
                photosSelectedFolderPath = url.path
                return url
            }
        }
        guard photosSelectedFolderPath.isEmpty == false else { return nil }
        return URL(fileURLWithPath: photosSelectedFolderPath, isDirectory: true)
    }
}

private struct PhotosCapsuleButtonStyle: PrimitiveButtonStyle {
    let active: Bool
    let phosphorColor: Color

    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundStyle(phosphorColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(active ? 0.62 : 0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(phosphorColor.opacity(active ? 0.8 : 0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct PhotosSourceButtonStyle: PrimitiveButtonStyle {
    let active: Bool
    let phosphorColor: Color

    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .font(.system(size: 19, weight: .bold, design: .monospaced))
                .foregroundStyle(phosphorColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(active ? 0.66 : 0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(phosphorColor.opacity(active ? 0.84 : 0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
