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
import SwiftyStoreKit

let XKCDY_PRO_DESCRIPTION = """
XKCDY Pro is a feature pack. Because notifications result in ongoing server costs, this is a subscription. Pro includes:
• Notifications when new comics are published
• Ability to set a custom accent color
• Custom app icons
• Support XKCDY's development
"""

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

struct SettingsGroup<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.label).font(Font.title.bold()).animation(.none)

            content
        }
        .padding(.bottom, 30)
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var title: Text
    var message: Text?
    var primaryButton: Alert.Button?
    var dismissButton = Alert.Button.cancel(Text("Cancel"))
}

struct SettingsSheet: View {
    var onDismiss: () -> Void
    @ObservedObject private var notificationPreference = NotificationPreferenceStore()
    @State private var alertItem: AlertItem?
    @ObservedObject private var userSettings = UserSettings()
    @State private var loading = false
    @State private var localizedPrice: String?

    func openAlert(title: String, message: String) {
        self.alertItem = AlertItem(title: Text(title), message: Text(message))
    }

    func markAllAsRead(_ isRead: Bool) {
        let realm = try! Realm()

        let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

        do {
            try realm.write {
                comics?.comics.setValue(isRead, forKey: "isRead")
            }
        } catch { }
    }

    func showPurchaseResult(result: PurchaseResult) {
        switch result {
        case .success:
            self.openAlert(title: "Success!", message: "You are now subscribed to XKCDY Pro.")
        case .error(let error):
            let errorMessage = SKErrorCodeMapping[error.code] ?? "Unknown error. Please contact support."

            self.openAlert(title: "Something went wrong", message: errorMessage)
        }

        self.loading = false
    }

    func handlePurchase() {
        self.loading = true

        withAnimation(.easeInOut) {
            IAPHelper.purchasePro(completion: self.showPurchaseResult)
        }
    }

    func handleRestorePurchase() {
        self.loading = true

        withAnimation(.easeInOut) {
            IAPHelper.restorePurchases { result in
                switch result {
                case .success:
                    self.openAlert(title: "Success!", message: "Purchase was restored.")
                case .failure(let error):
                    switch error {
                    case .restoreFailed:
                        self.openAlert(title: "Something went wrong", message: "Purchase restore failed.")
                    case .noPreviousValidPurchaseFound:
                        self.openAlert(title: "Something went wrong", message: "No previous valid purchase found.")
                    }
                }

                self.loading = false
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if self.loading {
                        HStack {
                            Spacer()
                            ActivityIndicator(style: .large)
                            Spacer()
                        }
                    }

                    SettingsGroup(label: "XKCDY Pro") {
                        if self.userSettings.isSubscribedToPro {
                            Toggle("Send notifications for new comics", isOn: self.$notificationPreference.isToggled)

                            NavigationLink(destination: TintColorPicker()) {
                                Text("Change accent color")
                            }

                            NavigationLink(destination: AppIconPicker()) {
                                Text("Change app icon")
                            }
                        } else {
                            Text(XKCDY_PRO_DESCRIPTION).fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 10)

                            HStack {
                                Button(action: self.handlePurchase) {
                                    Image(systemName: "bag.fill")

                                    Text("\(self.localizedPrice ?? "$2.99") / year")
                                }
                                .padding(10)
                                .foregroundColor(Color.white)
                                .background(Color.accentColor)
                                .cornerRadius(8)

                                Button(action: self.handleRestorePurchase) {
                                    Text("Restore purchase")
                                }
                            }
                        }
                    }

                    SettingsGroup(label: "Options") {
                        Toggle("Show all comics", isOn: self.$userSettings.showCOVIDComics)

                        Toggle("Show alt text in detail overlay", isOn: self.$userSettings.showAltInPager)

                        Toggle("Show comic number in detail overlay", isOn: self.$userSettings.showComicIdInPager)

                        Button(action: {
                            self.alertItem = AlertItem(title: Text("Confirm"), message: Text("Are you sure you want to mark all as read? This is not undoable."), primaryButton: Alert.Button.default(Text("Yes"), action: {
                                self.markAllAsRead(true)
                            }))
                        }) {
                            Text("Mark all as read")
                        }

                        Button(action: {
                            self.alertItem = AlertItem(title: Text("Confirm"), message: Text("Are you sure you want to mark all as unread? This is not undoable."), primaryButton: Alert.Button.default(Text("Yes"), action: {
                                self.markAllAsRead(false)
                            }))
                        }) {
                            Text("Mark all as unread")
                        }
                    }

                    SettingsGroup(label: "Feedback") {
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
                            UIApplication.shared.open(URL(string: "https://apps.apple.com/app/id1520259318?action=write-review")!)
                        }) {
                            Text("Rate on the App Store")
                        }
                    }

                    SettingsGroup(label: "Legal") {
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://xkcdy.com/privacy")!)
                        }) {
                            Text("Privacy Policy")
                        }

                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://xkcdy.com/terms")!)
                        }) {
                            Text("Terms of Use")
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
                .alert(item: $alertItem) { alertItem in
                    if let primaryButton = alertItem.primaryButton {
                        return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: alertItem.dismissButton)
                    }

                    return Alert(title: alertItem.title, message: alertItem.message)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // Yes, this is hacky but it works for now
        .alert(isPresented: self.$notificationPreference.showAlert) {
            Alert(title: Text(self.notificationPreference.alertTitle), message: Text(self.notificationPreference.alertMessage), primaryButton: Alert.Button.default(Text("OK"), action: {
                self.notificationPreference.alertClosed()
            }), secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {}))
        }
        .onAppear {
            SwiftyStoreKit.retrieveProductsInfo([XKCDYPro]) { result in
                if let product = result.retrievedProducts.first {
                    self.localizedPrice = product.localizedPrice!
                }
            }
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
