//
//  SettingsSheet.swift
//  XKCDY
//
//  Created by Max Isom on 7/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift

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
                Text("Miscellaneous Options")

                Button(action: {
                    self.showMarkReadAlert = true
                }) {
                    Text("Mark all as read")
                }

                Spacer()
            }
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
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet(onDismiss: {
            print("Dismissed")
        })
    }
}
