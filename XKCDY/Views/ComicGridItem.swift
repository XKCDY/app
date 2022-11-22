//
//  ComicGridItem.swift
//  XKCDY
//
//  Created by Max Isom on 7/11/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import Kingfisher
import RealmSwift

struct ComicGridItem: View {
    @ObservedObject var vm: ComicGridItemViewModel
    @EnvironmentObject var galleryVm: ComicGalleryViewModel
    @EnvironmentObject var store: Store
    @EnvironmentObject var namespaces: Namespaces

    private func isSelfOpenInPager() -> Bool {
        return galleryVm.pager.isOpen && galleryVm.pager.lastOpenComicId == vm.comic.id
    }

    var body: some View {
        ZStack {
            if isSelfOpenInPager() {
                EmptyView()
            } else {
                KFImage(self.vm.comic.getReasonableImageURL()!)
                    .placeholder {
                        Rectangle()
                            .fill(Color.secondary)
                            .opacity(0.2)
                    }
                    .resizable()
                    .aspectRatio(CGSize(width: vm.comic.getBestAvailableSize()?.width ?? 0, height: vm.comic.getBestAvailableSize()?.height ?? 0), contentMode: .fit)
                    .matchedGeometryEffect(id: String(self.vm.comic.id), in: self.namespaces.gallery)

                    .onTapGesture {
                        withAnimation {
                            self.galleryVm.pager = PagerState(lastOpenComicId: self.vm.comic.id, isOpen: true)
                        }
                    }
            }

            ComicBadge(comic: self.vm.comic)
                .padding(.trailing, 5)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .opacity(isSelfOpenInPager() ? 0 : 1)
                .animation(isSelfOpenInPager() ? .default : .easeInOut, value: isSelfOpenInPager())
        }
    }
}

struct ComicGridItem_Previews: PreviewProvider {
    static var previews: some View {
        ComicGridItem(vm: ComicGridItemViewModel(comic: Comic.getSample()))
    }
}
