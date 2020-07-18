//
//  UserSettings.swift
//  XKCDY
//
//  Created by Max Isom on 7/17/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    @Published var invertImages: Bool {
        didSet {
            UserDefaults.standard.set(invertImages, forKey: "invertImages")
        }
    }

    init() {
        self.invertImages = UserDefaults.standard.object(forKey: "invertImages") as? Bool ?? false
    }
}
