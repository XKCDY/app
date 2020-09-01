//
//  AppDelegate.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import UIKit
import BackgroundTasks
import RealmSwift
import SwiftyStoreKit
import class Kingfisher.ImagePrefetcher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.maxisom.XKCDY.comicFetcher", using: nil) { task in
            // swiftlint:disable:next force_cast
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }

        // Add transaction observer
        SwiftyStoreKit.completeTransactions(atomically: true) { _ in
            do {
                try IAPHelper.checkForPurchaseAndUpdate()
            } catch {}
        }

        // Cache product
        SwiftyStoreKit.retrieveProductsInfo([XKCDYPro], completion: {_ in })

        // Look for receipt and update server state
        do {
            try IAPHelper.checkForPurchaseAndUpdate()
        } catch {}

        // Set Realm file location
        let realmFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.maxisom.XKCDY")!
            .appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration.fileURL = realmFileURL

        // Disable at-rest encryption so background refresh works
        let realm = try! Realm()

        // Get our Realm file's parent directory
        let folderPath = realm.configuration.fileURL!.deletingLastPathComponent().path

        // Disable file protection for this directory
        try! FileManager.default.setAttributes([FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue): FileProtectionType.none], ofItemAtPath: folderPath)

        // Register for push notifications if enabled
        Notifications.registerIfEnabled()

        // Set delegate for handling notification opens
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func scheduleBackgroundRefresh() {
        let task = BGAppRefreshTaskRequest(identifier: "com.maxisom.XKCDY.comicFetcher")
        task.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            try BGTaskScheduler.shared.submit(task)
        } catch {
            print("Unable to sumit task: \(error.localizedDescription)")
        }
    }

    func handleAppRefreshTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        let store = Store()

        store.partialRefetchComics { result in
            switch result {
            case .success(let comicIds):
                // Cache images
                let realm = try! Realm()
                var urls: [URL] = []

                for id in comicIds {
                    if let comic = realm.object(ofType: Comic.self, forPrimaryKey: id) {
                        if let url = comic.getBestImageURL() {
                            urls.append(url)
                        }
                    }

                }

                ImagePrefetcher(urls: urls).start()

                task.setTaskCompleted(success: true)
            case .failure:
                task.setTaskCompleted(success: false)
            }
        }

        scheduleBackgroundRefresh()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Notifications.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let scene = UIApplication.shared.connectedScenes.first {
            if let sceneDelegate = scene.delegate {
                (sceneDelegate as? NotificationResponseHandler)?.handleNotificationResponse(response: response)
            }
        }

        completionHandler()
    }
}
