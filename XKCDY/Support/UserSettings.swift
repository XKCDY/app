//
//  UserSettings.swift
//  XKCDY
//
//  Created by Max Isom on 7/17/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import Combine
import UIKit

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

final class UserSettings: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    @UserDefault(key: "sendNotifications", defaultValue: false) var sendNotifications: Bool
    @UserDefault(key: "deviceToken", defaultValue: "") var deviceToken: String
    @UserDefault(key: "isSubscribedToPro", defaultValue: false) var isSubscribedToPro: Bool
    @UserDefault(key: "timeSpentInApp", defaultValue: 0) var timeSpentInApp: Int64
    @UserDefault(key: "showedProAlert", defaultValue: false) var showedProAlert: Bool
    @UserDefault(key: "showAltInPager", defaultValue: false) var showAltInPager: Bool
    @UserDefault(key: "showCOVIDComics", defaultValue: false) var showCOVIDComics: Bool
    var tintColor: UIColor {
        get {
            if let colorData = UserDefaults.standard.data(forKey: "tintColor") {
                do {
                    if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
                        return color
                    }
                } catch {}
            }

            return UIColor.systemBlue
        }
        set {
            var colorData: NSData?
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) as NSData?
                colorData = data
            } catch {}

            UserDefaults.standard.set(colorData, forKey: "tintColor")
        }
    }

    private var notificationSubscription: AnyCancellable?

    init() {
        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.objectWillChange.send()
        }
    }
}

let COVID_COMICS = [2275, 2276, 2277, 2278, 2279, 2280, 2281, 2282, 2283, 2284, 2285, 2286, 2287, 2289, 2290, 2291, 2292, 2293, 2294, 2296, 2298, 2299, 2300, 2302, 2305, 2306, 2330, 2331, 2332, 2333, 2338, 2339, 2342, 2346]
