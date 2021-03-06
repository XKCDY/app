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
        textField.contentVerticalAlignment = .center
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
    var onShuffle: () -> Void
    @Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject private var store: Store
    @State private var filteringDisabled = false
    @State private var textFieldSize = CGSize.zero

    init(isSearching: Binding<Bool>, onShuffle: @escaping () -> Void) {
        self._isSearching = isSearching
        self.onShuffle = onShuffle
        UITextField.appearance().clearButtonMode = .always
    }

    func isLargeScreen() -> Bool {
        self.verticalSizeClass == .some(.regular) && self.horizontalSizeClass == .some(.regular)
    }

    var body: some View {
        HStack {
            if self.isLargeScreen() {
                Spacer()
            }

            if !self.isSearching {
                Button(action: {
                    self.store.showSettings = true
                }) {
                    Image(systemName: "gear")
                        .modifier(RoundButtonIcon())
                }
                .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))

                if self.isLargeScreen() {
                    Spacer().frame(width: 25)
                } else {
                    Spacer()
                }

                Button(action: {
                    self.onShuffle()
                }) {
                    Image(systemName: "shuffle")
                        .modifier(RoundButtonIcon())
                }
                .disabled(self.filteringDisabled)
                .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))
            }

            if self.isLargeScreen() {
                Spacer().frame(width: 25)
            } else {
                Spacer()
            }

            HStack {
                if self.isSearching && self.isLargeScreen() {
                    GeometryReader { _ in
                        EmptyView()
                    }.frame(height: self.textFieldSize.height)
                }

                Button(action: {
                    withAnimation(.spring()) {
                        if self.isSearching {
                            self.store.searchText = ""
                        }

                        self.isSearching.toggle()
                    }
                }) {
                    Image(systemName: self.isSearching ? "arrow.left" : "magnifyingglass")
                        .transition(.opacity)
                        .modifier(RoundButtonIcon())
                }
                .transition(.move(edge: .trailing))
                .disabled(self.filteringDisabled)

                if self.isSearching {
                    // Yes, this whole thing is extremely ugly.
                    // I can't figure out a better way to do it.
                    GeometryReader { _ in
                        HStack(alignment: .center) {
                            Image(systemName: "magnifyingglass")

                            Text("")
                                .font(.title)
                                .padding(6)
                                .frame(maxWidth: .infinity)
                                .layoutPriority(1000)
                                .overlay(
                                    CustomTextField(placeholder: "Start typing...", text: self.$store.searchText, isFirstResponder: true)
                                )
                        }
                        .padding(12)
                        .background(Blur())
                        .cornerRadius(8)
                        .captureSize(in: self.$textFieldSize)
                    }
                    .frame(height: self.textFieldSize.height)
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
        .onReceive(self.store.objectWillChange) { _ in
            if self.store.filteredComics.count == 0 && self.store.searchText == "" {
                self.filteringDisabled = true
            } else {
                self.filteringDisabled = false
            }
        }
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtons(isSearching: .constant(true), onShuffle: {
            print("Shuffle button clicked.")
        })
    }
}
