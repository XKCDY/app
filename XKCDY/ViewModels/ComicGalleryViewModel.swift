//
//  ComicGalleryViewModel.swift
//  XKCDY
//
//  Created by Max Isom on 11/16/22.
//  Copyright © 2022 Max Isom. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIPager

struct PagerState: Equatable {
    var lastOpenComicId: Comic.ID?
    var isOpen = false
}

class ComicGalleryViewModel: ObservableObject {
    @Published var previousPager: PagerState?
    @Published var pagerPage: SwiftUIPager.Page = .first()
    @Published var pager = PagerState() {
        didSet {
            previousPager = oldValue

            // Update pager page
            if pager.lastOpenComicId != nil {
                let newIndex = self.store.filteredComics.firstIndex(where: { $0.id == pager.lastOpenComicId }) ?? 0

                if newIndex != self.pagerPage.index {
                    self.pagerPage.update(.new(index: newIndex))
                }
            }
        }
    }

    @ObservedObject var store: Store

    init(store: Store) {
        self.store = store
    }
}
