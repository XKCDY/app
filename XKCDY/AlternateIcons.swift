//
//  AlternateIcons.swift
//  XKCDY
//
//  Created by Max Isom on 7/28/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import UIKit

class AlternateIcons: ObservableObject {
    var iconNames: [String] = []
    @Published var currentIndex = 0

    init() {
        self.getAlternateIcons()

        if let currentIcon = UIApplication.shared.alternateIconName {
            self.currentIndex = iconNames.firstIndex(of: currentIcon) ?? 0
        }
    }

    func getAlternateIcons() {
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any], let alternateIcons = icons["CFBundleAlternateIcons"] as? [String: Any] {
            for (_, value ) in alternateIcons {
                guard let iconList = value as? [String: Any] else {return}
                guard let iconFiles = iconList["CFBundleIconFiles"] as? [String] else {return}

                guard let icon = iconFiles.first else {return}

                iconNames.append(icon)
            }
        }

        iconNames = iconNames.sorted()
    }
}
