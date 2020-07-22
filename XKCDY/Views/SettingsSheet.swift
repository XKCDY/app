//
//  SettingsSheet.swift
//  XKCDY
//
//  Created by Max Isom on 7/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift
import StoreKit

class NotificationPreferenceStore: ObservableObject {
    @Published var isToggled: Bool {
        willSet {
            self.handleNotificationToggle(newValue)
        }
    }
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @ObservedObject private var userSettings = UserSettings()

    init() {
        self.isToggled = UserSettings().sendNotifications
    }

    func handleNotificationToggle(_ toggled: Bool) {
        if toggled {
            Notifications.requestPermissionAndRegisterForNotifications { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.isToggled = false
                        self.alertTitle = "Whoops..."
                        self.alertMessage = "Looks like you denied notification permissions. Do you want to open Settings to allow notifications?"
                        self.showAlert = true
                    }
                }
            }
        } else {
            Notifications.unregister()
        }

        self.userSettings.sendNotifications = toggled
    }

    func alertClosed() {
        Notifications.openSettings()
    }
}

struct SettingsSheet: View {
    var onDismiss: () -> Void
    @State private var showMarkReadAlert = false
    @ObservedObject private var notificationPreference = NotificationPreferenceStore()

    func markAsRead() {
        let realm = try! Realm()

        let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

        do {
            try realm.write {
                comics?.comics.setValue(true, forKey: "isRead")
            }
        } catch { }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Miscellaneous Options").font(.system(size: 24))

                    Toggle("Send push notifications", isOn: self.$notificationPreference.isToggled)

                    Button(action: {
                        self.showMarkReadAlert = true
                    }) {
                        Text("Mark all as read")
                    }
                }
                .padding(.bottom)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Feedback").font(.system(size: 24))

                    Button(action: {
                        UIApplication.shared.open(URL(string: "mailto:app@xkcdy.com")!)
                    }) {
                        Text("Send an email")
                    }

                    Button(action: {
                        UIApplication.shared.open(URL(string: "https://github.com/XKCDY/app/issues")!)
                    }) {
                        Text("Open an issue")
                    }

                    Button(action: {
                        SKStoreReviewController.requestReview()
                    }) {
                        Text("Rate on the App Store")
                    }
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationBarItems(trailing: HStack {
                Button(action: onDismiss) {
                    Text("Done")
                }
            })
                .alert(isPresented: $showMarkReadAlert) {
                    Alert(title: Text("Confirm"), message: Text("Are you sure you want to mark all as read? This is not undoable."), primaryButton: Alert.Button.default(Text("Yes"), action: {
                        self.markAsRead()
                    }), secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {}))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: self.$notificationPreference.showAlert) {
            Alert(title: Text(self.notificationPreference.alertTitle), message: Text(self.notificationPreference.alertMessage), primaryButton: Alert.Button.default(Text("OK"), action: {
                self.notificationPreference.alertClosed()
            }), secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {}))
        }
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet(onDismiss: {
            print("Dismissed")
        })
    }
}
