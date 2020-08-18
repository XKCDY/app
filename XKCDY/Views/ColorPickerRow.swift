//
//  ColorPickerRow.swift
//  XKCDY
//
//  Created by Max Isom on 7/28/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct ColorOption: Identifiable, Hashable {
    var id = UUID()
    var color: UIColor
    var description: String
}

struct ColorPickerRow: View {
    var option: ColorOption
    var selected: Bool

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(option.color))
                .frame(width: 35, height: 35)
                .cornerRadius(8)

            Text(option.description)

            Spacer()

            if selected {
                Image(systemName: "checkmark")
                    .font(Font.body.bold())
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
}

struct ColorPickerRow_Previews: PreviewProvider {
    static var previews: some View {
        ColorPickerRow(option: ColorOption(color: UIColor.red, description: "Bright red"), selected: true)
    }
}
