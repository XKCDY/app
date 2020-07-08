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
import struct Kingfisher.KFImage

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

struct ComicsGridView: View {
    @State var columnMinSize: CGFloat = 150
    @State var inViewUrls: [String] = []
    var onComicOpen: () -> Void
    var hideCurrentComic: Bool
    @EnvironmentObject var store: Store
    @State private var scrollPosition: ASCollectionViewScrollPosition?
    @State private var showErrorAlert = false
    var comics: Results<Comic>

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

    var body: some View {
        AnyView(ASCollectionView(
            section: ASSection(
                id: 0,
                data: self.comics,
                dataID: \.self,
                onCellEvent: onCellEvent) { comic, _ in
                    GeometryReader { geom -> AnyView in
                        self.store.updatePosition(for: comic.id, at: CGRect(x: geom.frame(in: .global).midX, y: geom.frame(in: .global).midY, width: geom.size.width, height: geom.size.height))

                        let image = KFImage(comic.getBestImageURL()!).cancelOnDisappear(true).resizable().scaledToFill().frame(width: geom.size.width, height: geom.size.height).cornerRadius(2)
                            .onTapGesture {
                                self.store.currentComicId = comic.id
                                self.onComicOpen()
                        }

                        let shouldHide = self.hideCurrentComic && self.store.currentComicId == comic.id

                        return AnyView(
                            image.overlay(
                                ComicBadge(comic: comic).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 5)),
                                alignment: .bottomTrailing
                            )
                                .opacity(shouldHide ? 0 : 1)
                        )
                    }
        })
            .onPullToRefresh { endRefreshing in
                DispatchQueue.global(qos: .background).async {
                    self.store.refetchComics { result in
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
        .scrollPositionSetter($scrollPosition)
        .layout(self.layout)
        .customDelegate(WaterfallScreenLayoutDelegate.init)
        .contentInsets(.init(top: 0, left: 10, bottom: 0, right: 10))
        .onReceive(self.store.$currentComicId, perform: { _ in
            if self.store.currentComicId == nil {
                return
            }

            if let comicIndex = self.comics.firstIndex(where: { $0.id == self.store.currentComicId }) {
                self.scrollPosition = .indexPath(IndexPath(item: comicIndex, section: 0))
            }
        })
        )
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error Refreshing"), message: Text("There was an error refreshing. Try again later."), dismissButton: .default(Text("Ok")))
        }
    }
}

extension ComicsGridView {
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout {
            ASWaterfallLayout()
        }
    }
}
