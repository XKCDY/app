// https://gist.github.com/frankfka/2784adff55be72a4f044d8c2bcc9fd3f
import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
struct BackgroundGeometryReader: View {
    var body: some View {
        GeometryReader { geometry in
            return Color
                .clear
                .preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }
}
struct SizeAwareViewModifier: ViewModifier {

    @Binding private var viewSize: CGSize

    init(viewSize: Binding<CGSize>) {
        self._viewSize = viewSize
    }

    func body(content: Content) -> some View {
        content
            .background(BackgroundGeometryReader())
            .onPreferenceChange(SizePreferenceKey.self, perform: { if self.viewSize != $0 { self.viewSize = $0 }})
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

enum Page: String, CaseIterable, Hashable, Identifiable {
    case all
    case favorites

    var name: String {
        "\(self)".map { $0.isUppercase ? " \($0)" : "\($0)" }.joined().capitalized
    }

    var id: Page {self}
}

// Note: ideally we could pass in a CaseIterable enum as a parameter.
// Couldn't figure out a quick and dirty way to do it, so this works for now.
struct SegmentedPicker: View {
    private let ActiveSegmentColor: Color = Color(.tertiarySystemBackground)
    private let BackgroundColor: Color = Color(.secondarySystemBackground)
    private let ShadowColor: Color = Color.black.opacity(0.2)
    private let TextColor: Color = Color(.secondaryLabel)
    private let SelectedTextColor: Color = Color(.label)

    private let TextFont: Font = .system(size: 12)

    private let SegmentCornerRadius: CGFloat = 20
    private let ShadowRadius: CGFloat = 4
    private let SegmentXPadding: CGFloat = 16
    private let SegmentYPadding: CGFloat = 8
    private let PickerPadding: CGFloat = 4

    @State private var offset: CGSize = .zero

    // Stores the size of a segment, used to create the active segment rect
    @State private var segmentSize: CGSize = .zero
    // Rounded rectangle to denote active segment
    private var activeSegmentView: AnyView {
        // Don't show the active segment until we have initialized the view
        // This is required for `.animation()` to display properly, otherwise the animation will fire on init
        let isInitialized: Bool = segmentSize != .zero
        if !isInitialized { return EmptyView().eraseToAnyView() }
        return
            RoundedRectangle(cornerRadius: self.SegmentCornerRadius)
                .foregroundColor(self.ActiveSegmentColor)
                .shadow(color: self.ShadowColor, radius: self.ShadowRadius)
                .frame(width: self.segmentSize.width, height: self.segmentSize.height)
                .offset(x: self.computeActiveSegmentHorizontalOffset(), y: 0)
                .offset(x: self.offset.width)
                .animation(Animation.spring())
                .gesture(DragGesture().onChanged(self.handleDragChange).onEnded(self.handleDragEnd))
                .eraseToAnyView()
    }

    private func handleDragChange(gesture: DragGesture.Value) {
        if (0 <= gesture.translation.width + self.computeActiveSegmentHorizontalOffset()) && gesture.translation.width <= self.getMaxOffset() {
            self.offset = gesture.translation
        }
    }

    private func handleDragEnd(_: DragGesture.Value) {
        var i = (self.computeActiveSegmentHorizontalOffset() + self.offset.width) / (self.segmentSize.width + self.SegmentXPadding / 2)
        i.round()

        self.offset = .zero
        self.selection = Page.allCases[Int(i).clamped(to: 0...Page.allCases.count)]
    }

    @Binding private var selection: Page

    init(selection: Binding<Page>) {
        self._selection = selection
    }

    var body: some View {
        // Align the ZStack to the leading edge to make calculating offset on activeSegmentView easier
        ZStack(alignment: .leading) {
            // activeSegmentView indicates the current selection
            self.activeSegmentView
            HStack {
                ForEach(Page.allCases, id: \.self) { page in
                    self.getSegmentView(for: page)
                }
            }
        }
        .padding(self.PickerPadding)
        .background(self.BackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: self.SegmentCornerRadius))
    }

    // Helper method to compute the offset based on the selected index
    private func computeActiveSegmentHorizontalOffset() -> CGFloat {
        let index = Page.allCases.firstIndex(of: self.selection)!

        return CGFloat(index) * (self.segmentSize.width + self.SegmentXPadding / 2)
    }

    private func getMaxOffset() -> CGFloat {
        CGFloat(Page.allCases.count - 1) * (self.segmentSize.width + self.SegmentXPadding / 2)
    }

    // Gets text view for the segment
    private func getSegmentView(for page: Page) -> some View {
        let isSelected = self.selection == page
        return
            Text(page.name)
                .font(Font.body.bold())
                // Dark test for selected segment
                .foregroundColor(Color.white)
                .colorMultiply(isSelected ? self.SelectedTextColor: self.TextColor)
                .lineLimit(1)
                .padding(.vertical, self.SegmentYPadding)
                .padding(.horizontal, self.SegmentXPadding)
                .frame(minWidth: 0, maxWidth: .infinity)
                // Watch for the size of the
                .modifier(SizeAwareViewModifier(viewSize: self.$segmentSize))
                .gesture(DragGesture().onChanged(self.handleDragChange).onEnded(self.handleDragEnd))
                .onTapGesture { self.onItemTap(page: page) }
                .eraseToAnyView()
    }

    // On tap to change the selection
    private func onItemTap(page: Page) {
        self.selection = page
    }

}

struct PreviewView: View {
    @State var selection: Page = .all
    private let items: [String] = ["M", "T", "W", "T", "F"]

    var body: some View {
        SegmentedPicker(selection: self.$selection)
            .padding()
    }
}

struct SegmentedPicker_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
}
