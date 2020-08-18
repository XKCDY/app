//
//  SceneDelegate.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import UIKit
import SwiftUI
import RealmSwift
import Combine

class AnyGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        //To prevent keyboard hide and show when switching from one textfield to another
        if let textField = touches.first?.view, textField is UITextField {
            state = .failed
        } else {
            state = .began
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}

extension SceneDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

let timeTracker = TimeTracker()

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var store = Store()
    var notificationSubscriptions: [AnyCancellable] = []

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        //        let contentView = ContentView()
        //
        //        // Use a UIHostingController as window root view controller.
        //        if let windowScene = scene as? UIWindowScene {
        //            let window = UIWindow(windowScene: windowScene)
        //            window.rootViewController = UIHostingController(rootView: contentView)
        //            self.window = window
        //            window.makeKeyAndVisible()
        //        }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            let realm = try! Realm()
            var comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)
            if comics == nil {
                comics = try! realm.write { realm.create(Comics.self, value: []) }
            }

            let controller = UIHostingController(rootView: ContentView().environmentObject(comics!.comics).environmentObject(store))

            window.rootViewController = controller
            self.window = window
            window.makeKeyAndVisible()

            let tapGesture = AnyGestureRecognizer(target: window, action: #selector(UIView.endEditing))
            tapGesture.requiresExclusiveTouchType = false
            tapGesture.cancelsTouchesInView = false
            tapGesture.delegate = self //I don't use window as delegate to minimize possible side effects
            window.addGestureRecognizer(tapGesture)

            // Set and update tint color
            let userSettings = UserSettings()
            window.tintColor = userSettings.tintColor

            notificationSubscriptions.append(userSettings.objectWillChange.sink {
                window.tintColor = userSettings.tintColor
            })

            // Check for initial URL
            self.navigate(connectionOptions.urlContexts)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        self.navigate(URLContexts)
    }

    func navigate(_ URLContexts: Set<UIOpenURLContext>?) {
        if let urlContext = URLContexts?.first {
            if urlContext.url.host == "comics" {
                if let id = Int(urlContext.url.path.replacingOccurrences(of: "/", with: "")) {
                    let realm = try! Realm()

                    if realm.object(ofType: Comic.self, forPrimaryKey: id) != nil {
                        self.store.currentComicId = id
                        self.store.showPager = true
                    }
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        timeTracker.startTracker()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        // swiftlint:disable:next force_cast
        (UIApplication.shared.delegate as! AppDelegate).scheduleBackgroundRefresh()
        timeTracker.stopTracker()
    }

}
