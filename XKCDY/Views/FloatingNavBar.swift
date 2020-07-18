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
    var body: some View {
        ZStack(alignment: .bottom) {
            SegmentedPicker()
        }
        .padding()
        .shadow(radius: 2)
    }
}
