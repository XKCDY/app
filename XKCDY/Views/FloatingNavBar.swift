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

enum Pages: String, CaseIterable, Hashable, Identifiable {
    case all
    case favorites

    var name: String {
        "\(self)".map { $0.isUppercase ? " \($0)" : "\($0)" }.joined().capitalized
    }

    var id: Pages {self}
}

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
    @Binding var selected: Pages

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
            .fill(Color.clear)
            .background(Blur(style: .regular))
            .frame(height: 30)
            .cornerRadius(8)
                .overlay(ZStack {
                    Picker("Current page", selection: self.$selected) {
                        ForEach(Pages.allCases) { page in
                            Text(page.name).tag(page)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                    .animation(.easeInOut)
            }).animation(.easeInOut)
        }
        .cornerRadius(8)
        .padding()
        .shadow(radius: 2)
    }
}
