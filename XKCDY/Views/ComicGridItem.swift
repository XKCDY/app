//
//  ComicGridItem.swift
//  XKCDY
//
//  Created by Max Isom on 7/11/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI
import RealmSwift

struct AnimatableFontModifier: AnimatableModifier {
    var size: CGFloat

    var animatableData: CGFloat {
        get {size}
        set {size = newValue}
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size))
    }
}

extension View {
    func animatableFont( size: CGFloat) -> some View {
        self.modifier(AnimatableFontModifier(size: size))
    }
}

struct ComicGridItem: View {
    var comic: Comic
    var onTap: (Int) -> Void
    @EnvironmentObject var store: Store
    @State private var pulseEnded = false
    @State private var isLoaded = false

    var body: some View {
        GeometryReader { geom -> AnyView in
            self.store.updatePosition(for: self.comic.id, at: CGRect(x: geom.frame(in: .global).midX, y: geom.frame(in: .global).midY, width: geom.size.width, height: geom.size.height))

            let stack = ZStack {
                KFImage(self.comic.getBestImageURL()!, isLoaded: self.$isLoaded)
                    .cancelOnDisappear(true)
                .resizable()
                .scaledToFill()
                .opacity(self.isLoaded ? 1 : 0)

                Rectangle()
                    .fill(Color.secondary)
                    .opacity(self.pulseEnded ? 0.4 : 0.2)
                    .frame(width: geom.size.width, height: geom.size.height)
                    .animation(Animation.easeInOut(duration: 0.75).repeatForever())
                    .onAppear {
                        self.pulseEnded = true
                }
                .opacity(self.isLoaded ? 0 : 1)
            }
            .frame(width: geom.size.width, height: geom.size.height)
            .animation(.easeIn(duration: 0.2))
            .onTapGesture {
                self.onTap(self.comic.id)
            }

            return AnyView(
                stack
                    .overlay(
                        ComicBadge(comic: self.comic).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 5)),
                        alignment: .bottomTrailing
                )
            )
        }
    }
}

struct ComicGridItem_Previews: PreviewProvider {
    static var previews: some View {
        ComicGridItem(comic: Comic.getSample(), onTap: { id in
            print(id)
        })
    }
}
