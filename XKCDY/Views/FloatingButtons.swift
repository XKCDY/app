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
            .padding()
            .background(Blur())
            .clipShape(Circle())
            .font(.title)
            .shadow(radius: 2)
    }
}

struct FloatingButtons: View {
    @Binding var isSearching: Bool
    @Binding var searchText: String

    init(isSearching: Binding<Bool>, searchText: Binding<String>) {
        self._isSearching = isSearching
        self._searchText = searchText
        UITextField.appearance().clearButtonMode = .always
    }

    func handleTextFieldRef(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }

    var body: some View {
        HStack {
            if !self.isSearching {
                Button(action: {
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

                        TextField("Start typing...", text: $searchText)
                    }
                    .padding()
                    .background(Blur())
                    .cornerRadius(8)
                    .transition(AnyTransition.opacity.combined(with: .move(edge: .trailing)))
                    .introspectTextField(customize: self.handleTextFieldRef)
                }
            }
        }
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtons(isSearching: .constant(true), searchText: .constant(""))
    }
}
