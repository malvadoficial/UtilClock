//
//  FontRegistrar.swift
//  UtilClock
//
//  Created by José Manuel Rives on 19/2/26.
//

import Foundation
import CoreText

enum FontRegistrar {
    static func registerBundledFonts() {
        guard let resourceURL = Bundle.main.resourceURL else { return }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        ) else { return }

        let fontURLs = urls.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "ttf" || ext == "otf"
        }

        for url in fontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
