//
//  ContentView.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift
import ASCollectionView
import class Kingfisher.ImagePrefetcher

enum ScrollDirection {
    case up, down
}

class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate {
    func heightForHeader(sectionIndex: Int) -> CGFloat? {
        80
    }

    func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat {
        guard let comic: Comic = getDataForItem(at: indexPath) else { return 100 }
        let height = context.width / CGFloat(comic.imgs!.x1!.ratio)
        return height
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
    var comics: Results<Comic>
    @State private var lastScrollPositions: [CGFloat] = []
    @State private var shouldBlurStatusBar = false

    func onCellEvent(_ event: CellEvent<Comic>) {
        switch event {
        case let .prefetchForData(data):
            var urls: [URL] = []

            for comic in data {
                urls.append(comic.getBestImageURL()!)
            }

            ImagePrefetcher(urls: urls).start()
        default:
            return
        }
    }

    func handleComicTap(of comicId: Int) {
        self.store.currentComicId = comicId
        self.onComicOpen()
    }

    var body: some View {
        GeometryReader {geom in
            AnyView(ASCollectionView(
                section: ASSection(
                    id: 0,
                    data: self.comics,
                    dataID: \.self,
                    onCellEvent: self.onCellEvent) { comic, _ -> AnyView in
                        if self.hideCurrentComic && comic.id == self.store.currentComicId {
                            return AnyView(ComicGridItem(comic: comic, onTap: self.handleComicTap).hidden())
                        }

                        return AnyView(ComicGridItem(comic: comic, onTap: self.handleComicTap))
            })
                .onPullToRefresh { endRefreshing in
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
            .onScroll { (point, _) in
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
            .layout(self.layout)
            .customDelegate(WaterfallScreenLayoutDelegate.init)
            .contentInsets(.init(top: 0, left: 10, bottom: 0, right: 10))
            .onReceive(self.store.$debouncedCurrentComicId, perform: { _ -> Void in
                if self.store.currentComicId == nil {
                    return
                }

                if let comicIndex = self.comics.firstIndex(where: { $0.id == self.store.currentComicId }) {
                    self.scrollPosition = .indexPath(IndexPath(item: comicIndex, section: 0))
                }
            })
            )
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

extension ComicsGridView {
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout {
            let layout = ASWaterfallLayout()

            layout.columnSpacing = 10
            layout.itemSpacing = 10

            return layout
        }
    }
}
