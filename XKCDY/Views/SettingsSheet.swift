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

struct SettingsSheet: View {
    var onDismiss: () -> Void
    @State private var showMarkReadAlert = false

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
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet(onDismiss: {
            print("Dismissed")
        })
    }
}
