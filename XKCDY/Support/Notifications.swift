//
//  Notifications.swift
//  XKCDY
//
//  Created by Max Isom on 7/19/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//
import UIKit
import Foundation
import UserNotifications

struct Notifications {
    static func requestPermissionAndRegisterForNotifications(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .authorized {
                    self.register()
                    completion(true)
                } else if settings.authorizationStatus == .denied {
                    completion(false)
                }
            }
        }
    }

    static func openSettings() {
        DispatchQueue.main.async {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
    }

    static func register() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    static func registerIfEnabled() {
        let settings = UserSettings()

        if settings.sendNotifications {
            self.requestPermissionAndRegisterForNotifications(completion: {granted in
                if !granted {
                    settings.sendNotifications = false
                }
            })
        }
    }

    static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    static func unregister() {
        print("Unregistering...")
    }
}
