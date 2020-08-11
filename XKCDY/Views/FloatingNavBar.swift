//
//  FloatingNavBar.swift
//  DCKX
//
//  Created by Max Isom on 4/21/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import SwiftUI
import Introspect

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FloatingNavBarView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    func isLargeScreen() -> Bool {
        self.verticalSizeClass == .some(.regular) && self.horizontalSizeClass == .some(.regular)
    }

    var body: some View {
        GeometryReader { geom in
            VStack {
                Spacer()

                ZStack(alignment: .bottom) {
                    SegmentedPicker().frame(maxWidth: self.isLargeScreen() ? geom.size.width / 2 : .infinity)
                }
                .padding()
                .shadow(radius: 2)
            }
        }
    }
}
