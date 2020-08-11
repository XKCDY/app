//
//  FloatingButtons.swift
//  XKCDY
//
//  Created by Max Isom on 7/15/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct RoundButtonIcon: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Blur())
            .clipShape(Circle())
            .font(.title)
            .shadow(radius: 2)
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
        textField.placeholder = placeholder
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

struct FloatingButtons: View {
    @Binding var isSearching: Bool
    @Binding var searchText: String
    var onOpenSettings: () -> Void

    init(isSearching: Binding<Bool>, searchText: Binding<String>, onOpenSettings: @escaping () -> Void) {
        self._isSearching = isSearching
        self._searchText = searchText
        self.onOpenSettings = onOpenSettings
        UITextField.appearance().clearButtonMode = .always
    }

    var body: some View {
        HStack {
            if !self.isSearching {
                Button(action: {
                    self.onOpenSettings()
                }) {
                    Image(systemName: "gear")
                        .modifier(RoundButtonIcon())
                }
                .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))
            }

            Spacer()

            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        if self.isSearching {
                            self.searchText = ""
                        }

                        self.isSearching.toggle()
                    }
                }) {
                    Image(systemName: self.isSearching ? "arrow.left" : "magnifyingglass")
                        .transition(.opacity)
                        .id("FloatingButton" + String(self.isSearching))
                        .modifier(RoundButtonIcon())
                }
                .transition(.move(edge: .trailing))

                if self.isSearching {
                    HStack {
                        Image(systemName: "magnifyingglass")

                        // Hack to size text field correctly
                        Text("")
                            .font(.title)
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                CustomTextField(placeholder: "Start typing...", text: $searchText, isFirstResponder: true)
                            )
                    }
                    .padding(12)
                    .background(Blur())
                    .cornerRadius(8)
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtons(isSearching: .constant(true), searchText: .constant(""), onOpenSettings: {
            print("Settings button clicked.")
        })
    }
}
