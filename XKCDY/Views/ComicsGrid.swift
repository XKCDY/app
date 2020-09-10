//
//  ContentView.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import UIKit
import Combine
import RealmSwift
import ASCollectionView
import class Kingfisher.ImagePrefetcher
import class Kingfisher.ImageCache

enum ScrollDirection {
    case up, down
}

class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate {
    func heightForHeader(sectionIndex: Int) -> CGFloat? {
        0
    }

    func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat {
        guard let comic: Comic = getDataForItem(at: indexPath) else { return 100 }
        let height = context.width / CGFloat(comic.imgs!.x1!.ratio)
        return height
    }
}

extension ASWaterfallLayout.ColumnCount: Equatable {
    public static func == (lhs: ASWaterfallLayout.ColumnCount, rhs: ASWaterfallLayout.ColumnCount) -> Bool {
        switch (lhs, rhs) {
        case (.fixed(let a), .fixed(let b)):
            return a == b
        default:
            return false
        }

    }
}

@propertyWrapper struct PublishedWithoutViewUpdate<Value> {
    let publisher: PassthroughSubject<Void, Never>
    private var _wrappedValue: Value

    init(wrappedValue: Value) {
        self.publisher = PassthroughSubject()
        self._wrappedValue = wrappedValue
    }

    var wrappedValue: Value {
        get {
            _wrappedValue
        }

        set {
            _wrappedValue = newValue
            publisher.send()
        }
    }

    var projectedValue: PassthroughSubject<Void, Never> {
        //        get {
        self.publisher
        //        }
    }
}

class ScrollStateModel: ObservableObject {
    @Published var isScrolling = false
    @PublishedWithoutViewUpdate var scrollPosition: CGFloat = 0 {
        willSet {
            if !self.isScrolling {
                self.isScrolling = true
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        $scrollPosition
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.global())
            .sink { _ in
                DispatchQueue.main.async {
                    self.isScrolling = false
                }
            }
            .store(in: &cancellables)
    }
}

struct ComicsGridView: View {
    @State var columnMinSize: CGFloat = 150
    @State var inViewUrls: [String] = []
    var onComicOpen: () -> Void
    var hideCurrentComic: Bool
    @Binding var scrollDirection: ScrollDirection
    @EnvironmentObject var store: Store
    @State private var scrollPosition: ASCollectionViewScrollPosition?
    @State private var showErrorAlert = false
    @State private var lastScrollPositions: [CGFloat] = []
    @State private var shouldBlurStatusBar = false
    @ObservedObject private var scrollState = ScrollStateModel()

    func onCellEvent(_ event: CellEvent<Comic>) {
        switch event {
        case let .prefetchForData(data):
            ImagePrefetcher(urls: data.map {$0.getBestImageURL()!}).start()
        case let .cancelPrefetchForData(data):
            ImagePrefetcher(urls: data.map {$0.getBestImageURL()!}).stop()
        default:
            return
        }
    }

    func handleComicTap(of comicId: Int) {
        self.store.currentComicId = comicId
        self.onComicOpen()
    }

    func onPullToRefresh(_ endRefreshing: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.store.refetchComics { result -> Void in
                endRefreshing()

                switch result {
                case .success:
                    self.showErrorAlert = false
                case .failure:
                    self.showErrorAlert = true
                }
            }
        }
    }

    var body: some View {
        GeometryReader {geom in
            AnyView(ASCollectionView(
                        section: ASSection(
                            id: 0,
                            // Wrapping with Array() results in significantly better performance
                            // (even though it shouldn't) because Realm has its own extremely slow
                            // implementation of .firstIndex(), which ASCollectionView calls when rendering.
                            // Don't believe me? Try unwrapping it and scrolling to the bottom.
                            data: Array(self.store.frozenFilteredComics),
                            dataID: \.self,
                            onCellEvent: self.onCellEvent,
                            dragDropConfig: ASDragDropConfig<Comic>(dataBinding: .constant([]), dragEnabled: true, dropEnabled: false, reorderingEnabled: false)
                                .dragItemProvider { item in
                                    let provider = NSItemProvider()

                                    provider.registerObject(ofClass: UIImage.self, visibility: .all) { completion in
                                        ImageCache.default.retrieveImage(forKey: item.getBestImageURL()!.absoluteString) { result in
                                            switch result {
                                            case .success(let value):
                                                completion(value.image, nil)
                                            case .failure(let error):
                                                completion(nil, error)
                                            }
                                        }

                                        return Progress.discreteProgress(totalUnitCount: 0)
                                    }

                                    return provider
                                }
                        ) { comic, _ -> AnyView in
                            AnyView(
                                ComicGridItem(comic: comic, onTap: self.handleComicTap, hideBadge: self.hideCurrentComic && comic.id == self.store.currentComicId, isScrolling: self.scrollState.isScrolling)
                                    // Isn't SwiftUI fun?
                                    .environmentObject(self.store)
                                    .opacity(self.hideCurrentComic && comic.id == self.store.currentComicId ? 0 : 1)
                            )
                        })
                        .onPullToRefresh(self.onPullToRefresh)
                        .onScroll { (point, _) in
                            self.scrollState.scrollPosition = point.y

                            DispatchQueue.main.async {
                                self.shouldBlurStatusBar = point.y > 80

                                if point.y < 5 {
                                    self.scrollDirection = .up
                                    return
                                }

                                self.lastScrollPositions.append(point.y)

                                self.lastScrollPositions = self.lastScrollPositions.suffix(2)

                                if self.lastScrollPositions.count == 2 {
                                    self.scrollDirection = self.lastScrollPositions[0] < self.lastScrollPositions[1] ? .down : .up
                                }
                            }
                        }
                        .scrollPositionSetter(self.$scrollPosition)
                        .layout(createCustomLayout: ASWaterfallLayout.init) { layout in
                            let columns = min(Int(UIScreen.main.bounds.width / self.columnMinSize), 4)

                            if layout.columnSpacing != 10 {
                                layout.columnSpacing = 10
                            }
                            if layout.itemSpacing != 10 {
                                layout.itemSpacing = 10
                            }

                            if layout.numberOfColumns != .fixed(columns) {
                                layout.numberOfColumns = .fixed(columns)
                            }
                        }
                        .customDelegate(WaterfallScreenLayoutDelegate.init)
                        .contentInsets(.init(top: 40, left: 10, bottom: 80, right: 10))
            )
            .onReceive(self.store.$debouncedCurrentComicId, perform: { _ -> Void in
                if self.store.currentComicId == nil {
                    return
                }

                if let comicIndex = self.store.filteredComics.firstIndex(where: { $0.id == self.store.currentComicId }) {
                    self.scrollPosition = .indexPath(IndexPath(item: comicIndex, section: 0))
                }
            })
            .alert(isPresented: self.$showErrorAlert) {
                Alert(title: Text("Error Refreshing"), message: Text("There was an error refreshing. Try again later."), dismissButton: .default(Text("Ok")))
            }

            Rectangle().fill(Color.clear)
                .background(Blur(style: .regular))
                .frame(width: geom.size.width, height: geom.safeAreaInsets.top)
                .position(x: geom.size.width / 2, y: -geom.safeAreaInsets.top / 2)
                .opacity(self.shouldBlurStatusBar && !self.store.showPager ? 1 : 0)
                .animation(.default)
        }
    }
}
