//
//  ComicPager.swift
//  DCKX
//
//  Created by Max Isom on 5/8/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import SwiftUIPager
import RealmSwift
import KingfisherSwiftUI

func CGPointToDegree(_ point: CGPoint) -> Double {
    // Provides a directional bearing from (0,0) to the given point.
    // standard cartesian plain coords: X goes up, Y goes right
    // result returns degrees, -180 to 180 ish: 0 degrees = up, -90 = left, 90 = right
    let bearingRadians = atan2f(Float(point.y), Float(point.x))
    let bearingDegrees = Double(bearingRadians) * (180 / .pi)
    return bearingDegrees
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

let TIME_TO_MARK_AS_READ_MS: Int64 = 2 * 1000
// https://www.objc.io/blog/2019/09/26/swiftui-animation-timing-curves/
let SPRING_ANIMATION_TIME_SECONDS = 0.59

struct ComicPager: View {
    @State var page: Int = 0
    var onHide: () -> Void
    @State private var showOverlay = false
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 0
    @EnvironmentObject var store: Store
    @State private var hidden = false
    @State private var imageFrame: CGRect = CGRect()
    @State private var isLoading = true
    @State private var startedViewingAt: Int64 = Date().currentTimeMillis()
    @State private var showSheet = false
    @State private var activeSheet: ActiveSheet = .details
    @State private var isZoomed = false
    var comics: Results<Comic>

    init(onHide: @escaping () -> Void, comics: Results<Comic>) {
        self.onHide = onHide
        self.comics = comics
    }

    func handleDragChange(_ value: DragGesture.Value) {
        let translation = value.translation
        let angle = CGPointToDegree(value.startLocation - value.location)

        let isInBounds = (40 < angle && angle < 140) || (-140 < angle && angle < -40)

        if isInBounds {
            self.offset = translation
        }
    }

    func handleDragEnd(_: DragGesture.Value) {
        if abs(self.offset.height) > 100 {
            withAnimation(.spring()) {
                hidden = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + SPRING_ANIMATION_TIME_SECONDS) {
                self.onHide()
            }
        } else {
            self.offset = .zero
        }
    }

    func handleSingleTap() {
        withAnimation {
            showOverlay.toggle()
        }
    }

    func handleLongPress() {
        self.showOverlay = true
        self.activeSheet = .details
        self.showSheet = true
    }

    func getCurrentComic() -> Comic {
        return try! Realm().object(ofType: Comic.self, forPrimaryKey: self.store.currentComicId)!
    }

    func setPage() {
        self.page = self.comics.firstIndex(where: { $0.id == self.store.currentComicId }) ?? 0
    }

    func handleShuffle() {
        if comics.count > 0 {
            let randomComic = comics[Int(arc4random_uniform(UInt32(comics.count) - 1))]

            self.store.currentComicId = randomComic.id
            self.setPage()
        }
    }

    func handleImageScale(_ scale: CGFloat) {
        if scale == CGFloat(1) {
            self.isZoomed = false
        } else {
            self.isZoomed = true
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color(.systemBackground)
                        .opacity(self.hidden ? 0 : 1 - Double(abs(self.offset.height) / 200)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)

                ZStack {
                    Pager<Comic, Int, AnyView>(page: self.$page, data: Array(self.comics), id: \.id, content: { item in
                        AnyView(ZoomableImageView(imageURL: item.getBestImageURL()!, onSingleTap: self.handleSingleTap, onLongPress: self.handleLongPress, onScale: self.handleImageScale)
                            .frame(from: CGRect(origin: .zero, size: geometry.size))
                        )
                    })
                        .allowsDragging(!self.isZoomed)
                        .itemSpacing(self.offset == .zero ? 30 : 1000)
                        .onPageChanged({ newIndex in
                            let currentTimestamp = Date().currentTimeMillis()

                            if currentTimestamp > self.startedViewingAt + TIME_TO_MARK_AS_READ_MS {
                                let realm = try! Realm()
                                try! realm.write {
                                    self.getCurrentComic().isRead = true
                                }
                            }

                            self.startedViewingAt = Date().currentTimeMillis()

                            DispatchQueue.main.async {
                                self.store.currentComicId = self.comics[newIndex].id
                            }
                        })
                        .opacity(self.offset == .zero && !self.isLoading ? 1 : 0)
                        .edgesIgnoringSafeArea(.all)

                    Group<AnyView> {
                        let image = KFImage(self.getCurrentComic().getBestImageURL()).resizable().aspectRatio(contentMode: .fit)

                        guard let targetRect = self.store.positions[self.store.currentComicId ?? 100] else {
                            return AnyView(EmptyView())
                        }

                        // Get offset between parent coords and global coords
                        let globalOffset = geometry.frame(in: .global).origin

                        let origin = CGPoint(
                            x: targetRect.origin.x,
                            y: targetRect.origin.y - globalOffset.y + geometry.safeAreaInsets.top)

                        let framedSize = self.hidden ? CGSize(width: targetRect.size.width, height: targetRect.size.height) : geometry.size

                        return AnyView(
                            image
                                .frame(width: framedSize.width, height: framedSize.height)
                                .scaleEffect(self.hidden ? 1 : 1 - CGFloat(abs(self.offset.height) / geometry.size.width))
                                .offset(self.hidden ? .zero : self.offset)
                                .position(self.hidden ? origin : CGPoint(x: framedSize.width / 2 + geometry.safeAreaInsets.leading, y: framedSize.height / 2 + geometry.safeAreaInsets.top))
                                .edgesIgnoringSafeArea(.all)
                        )
                    }
                    .opacity(self.offset == .zero && !self.isLoading ? 0 : 1)
                }
                .simultaneousGesture(DragGesture(minimumDistance: 60)
                .onChanged(self.handleDragChange)
                .onEnded(self.handleDragEnd))

                ComicPagerOverlay(comic: self.getCurrentComic(), showSheet: self.$showSheet, activeSheet: self.$activeSheet, onShuffle: self.handleShuffle)
                    .opacity(self.offset == .zero ? 1 : 2 - Double(abs(self.offset.height) / 100))
                    .opacity(self.showOverlay && !self.hidden ? 1 : 0)
            }
        }
        .onAppear {
            self.setPage()

            self.hidden = true

            withAnimation(.spring()) {
                self.hidden = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + SPRING_ANIMATION_TIME_SECONDS) {
                self.isLoading = false
            }
        }
        .onReceive(self.store.$debouncedCurrentComicId) { _ in
            self.setPage()
        }
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
