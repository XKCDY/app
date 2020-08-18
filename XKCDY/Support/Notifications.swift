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
                print("Registering...")
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

        // Store device token
        UserSettings().deviceToken = token

        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }

        if UserSettings().isSubscribedToPro {
            API.putDeviceToken(token: token, version: appVersion) { result in
                switch result {
                case .success:
                    print("Registered for notifications with XKCDY")
                case .failure:
                    print("Failed to register for notifications with XKCDY")
                }
            }
        }
    }

    static func unregister() {
        print("Unregistering...")

        if UserSettings().deviceToken == "" {
            return
        }

        API.removeDeviceToken(token: UserSettings().deviceToken) { result in
            switch result {
            case .success:
                print("Successfully unregistered.")
                UserSettings().deviceToken = ""
                UserSettings().sendNotifications = false
            case .failure:
                print("Failed to unregister.")
            }
        }
    }
}
