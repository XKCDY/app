//
//  UserSettings.swift
//  XKCDY
//
//  Created by Max Isom on 7/17/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import Combine

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

    private var notificationSubscription: AnyCancellable?

    init() {
        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.objectWillChange.send()
        }
    }
}
