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
//    var onTap: (Int) -> Void
//    var hideBadge = false
//    @EnvironmentObject var store: Store

    var body: some View {
//                .onTapGesture {
//                self.onTap(self.comic.id)
//            }

        KFImage(self.vm.comic.getReasonableImageURL()!)
                                    .placeholder {
                                        Rectangle()
                                            .fill(Color.secondary)
                                            .opacity(0.2)
                                    }
                                    .cancelOnDisappear(true)
                                    .resizable()
                                    .aspectRatio(CGSize(width: vm.comic.getBestAvailableSize()?.width ?? 0, height: vm.comic.getBestAvailableSize()?.height ?? 0), contentMode: .fit)
                                    .overlay(ComicBadge(comic: self.vm.comic), alignment: .bottomTrailing)
    }
}

struct ComicGridItem_Previews: PreviewProvider {
    static var previews: some View {
        ComicGridItem(vm: ComicGridItemViewModel(comic: Comic.getSample()))
    }
}
