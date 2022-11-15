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
    var comic: Comic
//    var onTap: (Int) -> Void
//    var hideBadge = false
//    @EnvironmentObject var store: Store

    var body: some View {
//                .onTapGesture {
//                self.onTap(self.comic.id)
//            }

                KFImage(self.comic.getReasonableImageURL()!)
                                    .placeholder {
                                        Rectangle()
                                            .fill(Color.secondary)
                                            .opacity(0.2)
                                    }
                                    .cancelOnDisappear(true)
                                    .resizable()
                    .aspectRatio(CGSize(width: comic.getBestAvailableSize()?.width ?? 0, height: comic.getBestAvailableSize()?.height ?? 0), contentMode: .fit)
                    .overlay(ComicBadge(comic: self.comic), alignment: .bottomTrailing)
//                        ComicBadge(comic: self.comic)
//                            .opacity(self.hideBadge ? 0 : 1)
//                            .animation(.easeInOut, value: self.hideBadge).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 5)),
//                        alignment: .bottomTrailing
//                    )
    }
}

struct ComicGridItem_Previews: PreviewProvider {
    static var previews: some View {
        ComicGridItem(comic: Comic.getSample())
    }
}
