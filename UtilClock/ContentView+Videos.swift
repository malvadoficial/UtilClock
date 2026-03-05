import SwiftUI
#if os(macOS)
import AppKit
import Photos
import AVKit
import AVFoundation

extension ContentView {

    // MARK: - Computed helpers

    var videosItemCount: Int {
        videosSourceType == "album" ? videosAlbumAssetIDs.count : videosVideoURLs.count
    }

    var selectedVideosSourceLabel: String {
        if videosSourceType == "album", videosSelectedAlbumName.isEmpty == false {
            return videosSelectedAlbumName
        }
        if videosSelectedFolderPath.isEmpty == false {
            return videosSelectedFolderPath
        }
        return L10n.networkNoData
    }

    var canStartVideos: Bool {
        if videosLoading { return false }
        if videosSourceType == "album" {
            return videosAlbumAssetIDs.isEmpty == false
        }
        return videosVideoURLs.isEmpty == false
    }

    // MARK: - Router

    @ViewBuilder
    func videosUtilityView(dateSize: CGFloat) -> some View {
        if videosIsRunning {
            videosPlaybackView
        } else {
            videosLauncherView(dateSize: dateSize)
        }
    }

    // MARK: - Playback view

    var videosPlaybackView: some View {
        ZStack {
            Color.black

            if let player = videosPlayer {
                VideosAVPlayerView(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if videosTitleVisible || videosShowControls {
                VStack {
                    Text(videosCurrentTitle)
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            if videosShowControls {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        // Seek bar + time labels
                        let durationSeconds: Double = {
                            guard let d = videosPlayer?.currentItem?.duration,
                                  d.isNumeric else { return 0 }
                            return max(d.seconds, 0)
                        }()
                        VStack(spacing: 3) {
                            Slider(
                                value: $videosProgress,
                                in: 0...1,
                                onEditingChanged: { editing in
                                    videosIsSeeking = editing
                                    if !editing, durationSeconds > 0 {
                                        let target = CMTime(
                                            seconds: durationSeconds * videosProgress,
                                            preferredTimescale: 600
                                        )
                                        videosPlayer?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
                                    }
                                }
                            )
                            .tint(Color.white)
                            HStack {
                                Text(videosFormatTime(videosProgress * durationSeconds))
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Spacer()
                                Text(videosFormatTime(durationSeconds))
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }
                        // Transport buttons
                        HStack(spacing: 28) {
                            Button(action: videosGoPrevious) {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundStyle(Color.white)
                            }
                            .buttonStyle(.plain)

                            Button(action: videosTogglePlayPause) {
                                Image(systemName: videosIsPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30, weight: .regular))
                                    .foregroundStyle(Color.white)
                            }
                            .buttonStyle(.plain)

                            Button(action: videosGoNext) {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundStyle(Color.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 18)
                    .background(Color.black.opacity(0.52))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.22)) {
                videosShowControls = hovering
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            videosGoNext()
        }
        .onAppear {
            videosKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // Esc
                    stopVideosPlayback()
                    splitFullscreenTarget = .none
                    return nil
                }
                if event.keyCode == 49 { // Space
                    videosTogglePlayPause()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = videosKeyboardMonitor {
                NSEvent.removeMonitor(monitor)
                videosKeyboardMonitor = nil
            }
        }
    }

    // MARK: - Launcher view

    @ViewBuilder
    func videosLauncherView(dateSize: CGFloat) -> some View {
        GeometryReader { geometry in
            let colGap: CGFloat = 16
            let rightColWidth = max(280, min(360, geometry.size.width * 0.38))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: colGap) {
                    HStack(spacing: 10) {
                        Button(action: toggleVideosAlbumsPanel) { Text(L10n.videosAlbumButton) }
                            .buttonStyle(videosSourceButtonStyle(active: videosShowAlbumsList))
                        Button(action: chooseVideosFolder) { Text(L10n.videosFolderButton) }
                            .buttonStyle(videosSourceButtonStyle(active: videosSourceType == "folder"))
                    }
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 10) {
                            Toggle(isOn: $videosSoundEnabled) {
                                Text(L10n.videosSound)
                                    .font(.system(size: max(14, dateSize * 0.9), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                            }
                            .toggleStyle(.switch)
                            .onChange(of: videosSoundEnabled) { _, _ in
                                saveVideoModeSettings()
                                videosPlayer?.isMuted = !videosSoundEnabled
                            }
                        }
                        HStack(spacing: 10) {
                            Toggle(isOn: $videosShuffle) {
                                Text(L10n.videosShuffle)
                                    .font(.system(size: max(14, dateSize * 0.9), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorColor)
                            }
                            .toggleStyle(.switch)
                            .onChange(of: videosShuffle) { _, _ in saveVideoModeSettings() }
                        }
                    }
                    .frame(width: rightColWidth, alignment: .trailing)
                }

                if videosSourceType == "album",
                   videosPermissionStatus != "authorized",
                   videosPermissionStatus != "limited" {
                    HStack(spacing: 10) {
                        Text(videosPermissionHintText)
                            .font(.system(size: max(12, dateSize * 0.82), weight: .regular, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Button(action: requestVideosPermissionFromUI) {
                            Text(L10n.photosRequestPermission)
                        }
                        .buttonStyle(videosCapsuleButtonStyle(active: false))
                    }
                }

                HStack(alignment: .top, spacing: colGap) {
                    VStack(alignment: .leading, spacing: 6) {
                        if videosShowAlbumsList,
                           videosPermissionStatus == "authorized" || videosPermissionStatus == "limited" {
                            if videosAlbums.isEmpty {
                                Text(L10n.videosNoAlbums)
                                    .font(.system(size: max(13, dateSize * 0.86), weight: .regular, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                            } else {
                                ScrollView(showsIndicators: true) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(videosAlbums) { album in
                                            Button(action: { selectVideosAlbum(album) }) {
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
                                                .background(Color.black.opacity(videosSelectedAlbumID == album.id ? 0.5 : 0.22))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                        .stroke(phosphorColor.opacity(videosSelectedAlbumID == album.id ? 0.55 : 0.22), lineWidth: 1)
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
                                Text("\(L10n.videosSource):")
                                    .font(.system(size: max(13, dateSize * 0.85), weight: .semibold, design: .monospaced))
                                    .foregroundStyle(phosphorDim)
                                Text(selectedVideosSourceLabel)
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
                        Text("\(L10n.videosCount):")
                            .font(.system(size: max(13, dateSize * 0.85), weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorDim)
                        Text("\(videosItemCount)")
                            .font(.system(size: max(14, dateSize * 0.9), weight: .semibold, design: .monospaced))
                            .foregroundStyle(phosphorColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: startVideosPlayback) {
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
                    .disabled(canStartVideos == false)
                    .opacity(canStartVideos ? 1.0 : 0.48)
                }

                if videosLoading {
                    Text(L10n.videosLoading)
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

    // MARK: - Button styles

    func videosCapsuleButtonStyle(active: Bool) -> some PrimitiveButtonStyle {
        VideosCapsuleButtonStyle(active: active, phosphorColor: phosphorColor)
    }

    func videosSourceButtonStyle(active: Bool) -> some PrimitiveButtonStyle {
        VideosSourceButtonStyle(active: active, phosphorColor: phosphorColor)
    }

    // MARK: - Permission

    func refreshVideosPermissionStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        videosPermissionStatus = mapPhotosAuthStatus(status)
    }

    func requestVideosPermissionFromUI() {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    videosPermissionStatus = mapPhotosAuthStatus(status)
                    if status == .authorized || status == .limited {
                        loadVideosAlbums()
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

    var videosPermissionHintText: String {
        switch videosPermissionStatus {
        case "denied": return L10n.photosPermissionDenied
        case "restricted": return L10n.photosPermissionRestricted
        case "limited": return L10n.photosPermissionLimited
        case "notDetermined": return L10n.photosPermissionNotDetermined
        default: return L10n.photosPermissionUnknown
        }
    }

    // MARK: - Album panel

    func toggleVideosAlbumsPanel() {
        refreshVideosPermissionStatus()
        if videosPermissionStatus != "authorized" && videosPermissionStatus != "limited" {
            requestVideosPermissionFromUI()
            return
        }
        if videosAlbums.isEmpty {
            loadVideosAlbums()
        }
        videosShowAlbumsList.toggle()
    }

    func loadVideosAlbums() {
        guard videosPermissionStatus == "authorized" || videosPermissionStatus == "limited" else { return }
        let requestID = UUID()
        videosAlbumsLoadRequestID = requestID

        DispatchQueue.global(qos: .userInitiated).async {
            var byID: [String: PhotosAlbum] = [:]
            let videoFetchOpts = PHFetchOptions()
            videoFetchOpts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

            let sources: [(PHAssetCollectionType, PHAssetCollectionSubtype)] = [
                (.album, .any),
                (.smartAlbum, .any)
            ]
            for source in sources {
                let fetch = PHAssetCollection.fetchAssetCollections(with: source.0, subtype: source.1, options: nil)
                fetch.enumerateObjects { collection, _, _ in
                    let count = PHAsset.fetchAssets(in: collection, options: videoFetchOpts).count
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

            DispatchQueue.main.async {
                guard videosAlbumsLoadRequestID == requestID else { return }
                videosAlbums = result
            }
        }
    }

    func selectVideosAlbum(_ album: PhotosAlbum) {
        videosSourceType = "album"
        videosSelectedAlbumID = album.id
        videosSelectedAlbumName = album.title
        videosShowAlbumsList = false
        saveVideoModeSettings()
        loadVideosFromAlbum()
    }

    // MARK: - Folder

    func chooseVideosFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.select
        if panel.runModal() == .OK, let url = panel.url {
            videosSourceType = "folder"
            videosSelectedFolderPath = url.path
            videosSelectedFolderBookmark = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            videosShowAlbumsList = false
            saveVideoModeSettings()
            loadVideosFromFolder()
        }
    }

    func loadVideosFromFolder() {
        guard videosSourceType == "folder" else { return }
        guard let folderURL = resolveVideosFolderURL() else {
            videosLoading = false
            videosVideoURLs = []
            videosCurrentIndex = 0
            videosStartWhenReady = false
            return
        }
        videosLoading = true
        let requestID = UUID()
        videosFolderLoadRequestID = requestID

        DispatchQueue.global(qos: .userInitiated).async {
            let didAccess = folderURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess { folderURL.stopAccessingSecurityScopedResource() }
            }

            let fm = FileManager.default
            let validExtensions: Set<String> = ["mp4", "m4v", "mov"]
            var collected: [URL] = []

            let enumerator = fm.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            while let fileURL = enumerator?.nextObject() as? URL {
                let ext = fileURL.pathExtension.lowercased()
                if validExtensions.contains(ext) {
                    collected.append(fileURL)
                }
            }

            let sorted = collected
                .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

            DispatchQueue.main.async {
                guard videosFolderLoadRequestID == requestID else { return }
                videosLoading = false
                videosVideoURLs = sorted
                videosCurrentIndex = 0
                if videosStartWhenReady {
                    beginVideosPlayback()
                }
            }
        }
    }

    func resolveVideosFolderURL() -> URL? {
        if let bookmark = videosSelectedFolderBookmark {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale {
                    videosSelectedFolderBookmark = try? url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    saveVideoModeSettings()
                }
                videosSelectedFolderPath = url.path
                return url
            }
        }
        guard videosSelectedFolderPath.isEmpty == false else { return nil }
        return URL(fileURLWithPath: videosSelectedFolderPath, isDirectory: true)
    }

    // MARK: - Album loading

    func loadVideosFromAlbum() {
        guard videosSourceType == "album", videosSelectedAlbumID.isEmpty == false else { return }
        guard videosPermissionStatus == "authorized" || videosPermissionStatus == "limited" else {
            videosAlbumAssetIDs = []
            return
        }

        videosLoading = true
        let selectedID = videosSelectedAlbumID

        DispatchQueue.global(qos: .userInitiated).async {
            let fetchCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [selectedID], options: nil)
            guard let collection = fetchCollection.firstObject else {
                DispatchQueue.main.async { videosLoading = false; videosAlbumAssetIDs = [] }
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)

            var ids: [String] = []
            assets.enumerateObjects { asset, _, _ in ids.append(asset.localIdentifier) }

            DispatchQueue.main.async {
                videosLoading = false
                videosAlbumAssetIDs = ids
                videosCurrentIndex = 0
                if videosStartWhenReady {
                    beginVideosPlayback()
                }
            }
        }
    }

    // MARK: - Playback control

    func startVideosPlayback() {
        videosStartWhenReady = false
        if videosSourceType == "album" {
            if videosAlbumAssetIDs.isEmpty {
                videosStartWhenReady = true
                loadVideosFromAlbum()
                return
            }
        } else {
            if videosVideoURLs.isEmpty {
                videosStartWhenReady = true
                loadVideosFromFolder()
                return
            }
        }
        beginVideosPlayback()
    }

    func beginVideosPlayback() {
        let count = videosItemCount
        guard count > 0 else {
            videosStartWhenReady = false
            return
        }

        let startIndex = videosShuffle ? Int.random(in: 0..<count) : 0
        videosCurrentIndex = startIndex
        videosIsRunning = true
        splitFullscreenTarget = .bottom
        videosStartWhenReady = false

        if videosSourceType == "folder" {
            videosFolderScopedURL = resolveVideosFolderURL()
            _ = videosFolderScopedURL?.startAccessingSecurityScopedResource()
        }

        playVideoAtCurrentIndex()
    }

    func playVideoAtCurrentIndex() {
        videosProgress = 0
        if videosSourceType == "folder" {
            guard videosCurrentIndex < videosVideoURLs.count else { return }
            let url = videosVideoURLs[videosCurrentIndex]
            let item = AVPlayerItem(url: url)
            if let player = videosPlayer {
                player.replaceCurrentItem(with: item)
            } else {
                videosPlayer = AVPlayer(playerItem: item)
            }
            videosPlayer?.isMuted = !videosSoundEnabled
            setupVideosTimeObserver()
            videosPlayer?.play()
            videosIsPlaying = true
            showVideoTitle(url.deletingPathExtension().lastPathComponent)
        } else {
            guard videosCurrentIndex < videosAlbumAssetIDs.count else { return }
            let localID = videosAlbumAssetIDs[videosCurrentIndex]
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
            guard let asset = fetchResult.firstObject else { return }

            let resources = PHAssetResource.assetResources(for: asset)
            let filename = resources.first(where: { $0.type == .video })?.originalFilename
                ?? resources.first?.originalFilename
                ?? "Video \(videosCurrentIndex + 1)"
            showVideoTitle(URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent)

            let opts = PHVideoRequestOptions()
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .highQualityFormat

            PHImageManager.default().requestAVAsset(forVideo: asset, options: opts) { avAsset, _, _ in
                guard let avAsset else { return }
                DispatchQueue.main.async {
                    let item = AVPlayerItem(asset: avAsset)
                    if let player = videosPlayer {
                        player.replaceCurrentItem(with: item)
                    } else {
                        videosPlayer = AVPlayer(playerItem: item)
                    }
                    videosPlayer?.isMuted = !videosSoundEnabled
                    setupVideosTimeObserver()
                    videosPlayer?.play()
                    videosIsPlaying = true
                }
            }
        }
    }

    func showVideoTitle(_ title: String) {
        videosTitleTimer?.invalidate()
        videosCurrentTitle = title
        withAnimation(.easeIn(duration: 0.25)) {
            videosTitleVisible = true
        }
        videosTitleTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.5)) {
                    videosTitleVisible = false
                }
            }
        }
    }

    func setupVideosTimeObserver() {
        if let observer = videosTimeObserver {
            videosPlayer?.removeTimeObserver(observer)
            videosTimeObserver = nil
        }
        videosProgress = 0
        guard let player = videosPlayer else { return }
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        videosTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            guard !videosIsSeeking,
                  let item = videosPlayer?.currentItem,
                  item.duration.isNumeric,
                  item.duration.seconds > 0 else { return }
            videosProgress = min(1.0, (videosPlayer?.currentTime().seconds ?? 0) / item.duration.seconds)
        }
    }

    func videosFormatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    func stopVideosPlayback() {
        if let observer = videosTimeObserver {
            videosPlayer?.removeTimeObserver(observer)
            videosTimeObserver = nil
        }
        videosProgress = 0
        videosPlayer?.pause()
        videosPlayer?.replaceCurrentItem(with: nil)
        videosPlayer = nil
        videosIsPlaying = false
        videosIsRunning = false
        videosShowControls = false
        videosTitleTimer?.invalidate()
        videosTitleTimer = nil
        videosTitleVisible = false
        if let monitor = videosKeyboardMonitor {
            NSEvent.removeMonitor(monitor)
            videosKeyboardMonitor = nil
        }
        videosFolderScopedURL?.stopAccessingSecurityScopedResource()
        videosFolderScopedURL = nil
    }

    func videosTogglePlayPause() {
        guard let player = videosPlayer else { return }
        if videosIsPlaying {
            player.pause()
            videosIsPlaying = false
        } else {
            player.play()
            videosIsPlaying = true
        }
    }

    func videosGoNext() {
        let count = videosItemCount
        guard count > 0 else { return }

        if videosShuffle {
            var next = videosCurrentIndex
            if count > 1 {
                while next == videosCurrentIndex { next = Int.random(in: 0..<count) }
            }
            videosCurrentIndex = next
        } else {
            videosCurrentIndex = (videosCurrentIndex + 1) % count
        }
        playVideoAtCurrentIndex()
    }

    func videosGoPrevious() {
        let count = videosItemCount
        guard count > 0 else { return }
        videosCurrentIndex = (videosCurrentIndex - 1 + count) % count
        playVideoAtCurrentIndex()
    }

    // MARK: - Settings persistence

    func saveVideoModeSettings() {
        let defaults = UserDefaults.standard
        defaults.set(videosSelectedFolderPath, forKey: "utilclock.videos.folderPath")
        defaults.set(videosSoundEnabled, forKey: "utilclock.videos.sound")
        defaults.set(videosShuffle, forKey: "utilclock.videos.shuffle")
        defaults.set(videosSelectedFolderBookmark, forKey: "utilclock.videos.folderBookmark")
        defaults.set(videosSourceType, forKey: "utilclock.videos.sourceType")
        defaults.set(videosSelectedAlbumID, forKey: "utilclock.videos.albumID")
        defaults.set(videosSelectedAlbumName, forKey: "utilclock.videos.albumName")
    }

    func refreshVideosModeIfNeeded() {
        refreshVideosPermissionStatus()
        if videosSourceType == "album" {
            loadVideosAlbums()
            loadVideosFromAlbum()
        } else {
            loadVideosFromFolder()
        }
    }

    func hydrateVideosSourcesIfNeeded() {
        guard videosSourcesHydrated == false else { return }
        videosSourcesHydrated = true
        refreshVideosModeIfNeeded()
    }

    func loadVideoModeSettings(loadSources: Bool = true) {
        let defaults = UserDefaults.standard
        videosSelectedFolderPath = defaults.string(forKey: "utilclock.videos.folderPath") ?? ""
        videosSoundEnabled = defaults.object(forKey: "utilclock.videos.sound") as? Bool ?? true
        videosShuffle = defaults.object(forKey: "utilclock.videos.shuffle") as? Bool ?? true
        videosSelectedFolderBookmark = defaults.data(forKey: "utilclock.videos.folderBookmark")
        videosSourceType = defaults.string(forKey: "utilclock.videos.sourceType") ?? "folder"
        videosSelectedAlbumID = defaults.string(forKey: "utilclock.videos.albumID") ?? ""
        videosSelectedAlbumName = defaults.string(forKey: "utilclock.videos.albumName") ?? ""

        refreshVideosPermissionStatus()
        videosSourcesHydrated = false
        if loadSources {
            hydrateVideosSourcesIfNeeded()
        }
    }
}

// MARK: - AVPlayerView wrapper

private struct VideosAVPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.player = player
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

// MARK: - Button styles

private struct VideosCapsuleButtonStyle: PrimitiveButtonStyle {
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

private struct VideosSourceButtonStyle: PrimitiveButtonStyle {
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
#endif
