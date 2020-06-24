import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter {$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

struct SearchBar: View {
    @Binding var text: String
    @State var focused = false

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField("Search", text: $text, onEditingChanged: { editingChanged in
                    withAnimation {
                        self.focused = editingChanged
                    }
                })
                    .foregroundColor(.primary)

                if text.isEmpty {
                    EmptyView()
                } else {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)

            if focused {
                 Button(action: {
                    withAnimation {
                        self.text = ""
                        UIApplication.shared.endEditing(true)
                    }
                 }) {
                     Text("Cancel")
                 }
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
}
