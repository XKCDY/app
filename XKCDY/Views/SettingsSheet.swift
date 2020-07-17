//
//  SettingsSheet.swift
//  XKCDY
//
//  Created by Max Isom on 7/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct SettingsSheet: View {
    var onDismiss: () -> Void
    var body: some View {
        NavigationView {
            VStack {
                Text("Future home for settings.").font(.title)
                    .navigationBarTitle(Text("Settings"), displayMode: .inline)
                    .navigationBarItems(trailing: HStack {
                        Button(action: onDismiss) {
                            Text("Done")
                        }
                    })
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
