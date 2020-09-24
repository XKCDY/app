//
//  ProgressBar.swift
//  XKCDY
//
//  Created by Max Isom on 9/23/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var value: Float

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geom.size.width, height: geom.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.accentColor)

                Rectangle()
                    .frame(width: min(CGFloat(value) * geom.size.width, geom.size.width), height: geom.size.height)
                    .foregroundColor(Color.accentColor)
                    .animation(.linear)
            }.cornerRadius(45)
        }.frame(height: 20)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(value: .constant(0.5))
    }
}
