//
//  ColorPicker.swift
//  XKCDY
//
//  Created by Max Isom on 7/28/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

let COLORS_TO_PICK_FROM: [ColorOption] = [
    ColorOption(color: UIColor.systemBlue, description: "Default"),
    ColorOption(color: UIColor(red: 0.18, green: 0.80, blue: 0.80, alpha: 1.00), description: "Surf Water"),
    ColorOption(color: UIColor(red: 0.15, green: 0.67, blue: 0.98, alpha: 1.00), description: "Pool Water"),
    ColorOption(color: UIColor(red: 0.48, green: 0.30, blue: 0.91, alpha: 1.00), description: "Night Sky"),
    ColorOption(color: UIColor(red: 0.80, green: 0.30, blue: 0.87, alpha: 1.00), description: "Clematis"),
    ColorOption(color: UIColor(red: 0.95, green: 0.39, blue: 0.66, alpha: 1.00), description: "Panther"),
    ColorOption(color: UIColor(red: 1.00, green: 0.26, blue: 0.41, alpha: 1.00), description: "Not Quite Red"),
    ColorOption(color: UIColor(red: 0.99, green: 0.69, blue: 0.23, alpha: 1.00), description: "Sunset"),
    ColorOption(color: UIColor(red: 0.98, green: 0.89, blue: 0.22, alpha: 1.00), description: "Not Swimming Water"),
    ColorOption(color: UIColor(red: 0.54, green: 0.87, blue: 0.16, alpha: 1.00), description: "Lime Zest"),
    ColorOption(color: UIColor(red: 0.17, green: 0.85, blue: 0.42, alpha: 1.00), description: "Hellebores")
]

struct TintColorPicker: View {
    @ObservedObject private var userSettings = UserSettings()

    var body: some View {
        VStack {
            List {
                ForEach(COLORS_TO_PICK_FROM, id: \.self) { option in
                    ColorPickerRow(option: option, selected: option.color == self.userSettings.tintColor)
                        .onTapGesture {
                            self.userSettings.tintColor = option.color
                    }
                }
            }
            .padding(.top)
        }
        .navigationBarTitle(Text("Pick a color"), displayMode: .inline)
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        TintColorPicker()
    }
}
