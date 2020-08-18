//
//  AppIconPicker.swift
//  XKCDY
//
//  Created by Max Isom on 7/28/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

let ICON_NAME_MAPPING = [
    "beret": "Beret",
    "beret-dark": "Beret Dark",
    "megan": "Megan",
    "megan-dark": "Megan Dark",
    "blackhat": "Blackhat",
    "blackhat-dark": "Blackhat Dark"
]

struct AppIconPicker: View {
    @ObservedObject var alternateIcons = AlternateIcons()

    func mapNameToDescription(_ name: String) -> String {
        return ICON_NAME_MAPPING[name] ?? name
    }

    var body: some View {
        VStack {
            List {
                ForEach(0 ..< alternateIcons.iconNames.count) { i in
                    HStack {
                        Image(uiImage: UIImage(named: self.alternateIcons.iconNames[i]) ?? UIImage())
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 40, height: 40)
                            .cornerRadius(10)

                        Text(self.mapNameToDescription(self.alternateIcons.iconNames[i]))

                        Spacer()

                        if i == self.alternateIcons.currentIndex {
                            Image(systemName: "checkmark")
                                .font(Font.body.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.alternateIcons.currentIndex = i
                    }
                }
            }
            .padding(.top)
        }
        .navigationBarTitle(Text("Pick an icon"), displayMode: .inline)
        .onReceive([self.alternateIcons.currentIndex].publisher.first()) { value in
            let i = self.alternateIcons.iconNames.firstIndex(of: UIApplication.shared.alternateIconName ?? "") ?? 0

            if value != i {
                UIApplication.shared.setAlternateIconName(self.alternateIcons.iconNames[value])
            }
        }
    }
}

struct AppIconPicker_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPicker()
    }
}
