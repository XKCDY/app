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
import class Kingfisher.ImageCache

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
let SPRING_ANIMATION_TIME_SECONDS = 0.60

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

    init(onHide: @escaping () -> Void) {
        self.onHide = onHide
    }

    func closePager() {
        withAnimation(.spring()) {
            hidden = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + SPRING_ANIMATION_TIME_SECONDS) {
            self.onHide()
        }
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
            self.closePager()
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

    func setPage() {
        self.page = self.store.filteredComics.firstIndex(where: { $0.id == self.store.currentComicId }) ?? 0
    }

    func handleShuffle() {
        self.store.shuffle {
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

    func getImage(for comic: Comic) -> ComicImage? {
        return comic.imgs?.x2 ?? comic.imgs?.x1
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
                    Pager<Comic, Int, Group>(page: self.$page, data: self.store.filteredComics.map({$0}), id: \.id, content: { item in
                        Group {
                            if SUPPORTED_SPECIAL_COMICS.contains(item.id) {
                                SpecialComicViewer(id: item.id)
                                    .contentShape(Rectangle())
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                    .onTapGesture {
                                        self.handleSingleTap()
                                    }
                            } else {
                                ZoomableImageView(imageURL: self.getImage(for: item)!.url!, onSingleTap: self.handleSingleTap, onLongPress: self.handleLongPress, onScale: self.handleImageScale, dimensions: self.getImage(for: item)!.size)
                                    .frame(from: CGRect(origin: .zero, size: geometry.size))
                            }
                        }
                    })
                    .allowsDragging(!self.isZoomed)
                    .itemSpacing(self.offset == .zero ? 30 : 1000)
                    .onPageChanged({ newIndex in
                        if newIndex == -1 {
                            return
                        }

                        let currentTimestamp = Date().currentTimeMillis()

                        if currentTimestamp > self.startedViewingAt + TIME_TO_MARK_AS_READ_MS {
                            let realm = try! Realm()
                            try! realm.write {
                                self.store.comic.isRead = true
                            }
                        }

                        self.startedViewingAt = Date().currentTimeMillis()

                        DispatchQueue.main.async {
                            self.store.currentComicId = self.store.filteredComics[newIndex].id
                        }
                    })
                    .opacity(self.offset == .zero && !self.isLoading ? 1 : 0)
                    .edgesIgnoringSafeArea(.all)

                    Group<AnyView> {
                        var imageUrl = self.store.comic.getReasonableImageURL()

                        if let bestUrl = self.store.comic.getBestImageURL() {
                            if ImageCache.default.isCached(forKey: bestUrl.absoluteString) {
                                imageUrl = bestUrl
                            }
                        }

                        let image = KFImage(imageUrl).resizable().aspectRatio(contentMode: .fit)

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

                ComicPagerOverlay(showSheet: self.$showSheet, activeSheet: self.$activeSheet, onShuffle: self.handleShuffle, onClose: {
                    // Make sure closing animation applies
                    self.offset = CGSize(width: 0.1, height: 0.1)

                    self.closePager()
                })
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.offset = .zero
        }
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
