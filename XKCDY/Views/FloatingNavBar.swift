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

struct CustomTextField: UIViewRepresentable {

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var didBecomeFirstResponder = false

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

    }

    var placeholder: String
    @Binding var text: String
    var isFirstResponder: Bool = false

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = self.placeholder
        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(text: $text)
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FloatingNavBarView: View {
    @State var pages: [String] = []
    @Binding var selected: String
    @Binding var searchText: String

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
            .fill(Color.clear)
            .background(Blur(style: .regular))
            .frame(height: selected == "Search" ? 50 : 30)
            .cornerRadius(8)
                .overlay(ZStack {

                if selected == "Search" {
                    HStack {
                        Image(systemName: "magnifyingglass")

                        CustomTextField(placeholder: "Start typing...", text: $searchText, isFirstResponder: true)

                        Button(action: {
                            UIApplication.shared.endEditing()
                            self.selected = "Home"
                        }, label: {
                            Text("Cancel")
                        })
                    }.padding()
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                    .animation(.easeInOut)
                } else {
                    Picker("Current page", selection: self.$selected) {
                        ForEach(0 ..< self.pages.count) {
                            Text(self.pages[$0]).tag(self.pages[$0])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                    .animation(.easeInOut)
                }
            }).animation(.easeInOut)
        }
        .cornerRadius(8)
        .padding()
        .shadow(radius: 2)
    }
}
