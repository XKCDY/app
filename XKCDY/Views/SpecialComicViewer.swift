//
//  SpecialComicViewer.swift
//  XKCDY
//
//  Created by Max Isom on 9/18/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import SwiftUIPager
import RealmSwift
import KingfisherSwiftUI
import class Kingfisher.ImagePrefetcher
import protocol Kingfisher.Resource
import class Kingfisher.ImageCache

public let SUPPORTED_SPECIAL_COMICS = [1190]

let TIME_FRAME_DIMENSIONS = CGSize(width: 553, height: 395)

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

struct TimeComicViewer: View {
    @State private var loadingProgress: Float = 0.0
    @State private var loading = false
    @EnvironmentObject private var store: Store
    @State private var currentFrame: Double = 0
    @State private var areAllFramesCached = true

    func cacheImages() {
        loading = true

        var urls: [URL] = []

        for frame in store.timeComicFrames {
            if let url = frame.getURL() {
                urls.append(url)
            }
        }

        let fetcher = ImagePrefetcher(urls: urls, progressBlock: self.onProgressUpdate, completionHandler: { _, _, _  in
            loading = false
            areAllFramesCached = true
        })

        fetcher.maxConcurrentDownloads = 30
        fetcher.start()
    }

    func onProgressUpdate(_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) {
        let numberOfLoadedImages = skippedResources.count + completedResources.count

        loadingProgress = Float(numberOfLoadedImages) / Float(store.timeComicFrames.count)
    }

    func isLandscape(_ geom: GeometryProxy) -> Bool {
        geom.size.width > geom.size.height
    }

    func getImageWidthHeight(_ geom: GeometryProxy) -> CGSize {
        let isLandscape = geom.size.width > geom.size.height

        let ratio = CGFloat(TIME_FRAME_DIMENSIONS.width) / CGFloat(TIME_FRAME_DIMENSIONS.height)

        if isLandscape {
            return CGSize(width: geom.size.height / (1 / ratio), height: geom.size.height)
        }

        return CGSize(width: geom.size.width, height: geom.size.width / ratio)
    }

    func getFrameRange() -> ClosedRange<Double> {
        (0...Double(store.timeComicFrames.count - 1))
    }

    func handleAppear() {
        for frame in store.timeComicFrames {
            if let url = frame.getURL() {
                if !ImageCache.default.isCached(forKey: url.absoluteString) {
                    self.areAllFramesCached = false
                    break
                }
            }
        }
    }

    var body: some View {
        Group {
            if self.loading {
                ProgressBar(value: $loadingProgress).padding()
            } else if store.timeComicFrames.count > 0 {
                GeometryReader { geom in
                    VStack {
                        if !self.isLandscape(geom) {
                            Spacer()

                            HStack {
                                Spacer()

                                Text("\(Int(currentFrame + 1)) / \(store.timeComicFrames.count)")
                                    .font(.headline)
                                    .animation(.none)
                                    .transition(.identity)
                            }
                        }

                        HStack {
                            if self.isLandscape(geom) {
                                HStack {
                                    Slider(value: $currentFrame, in: getFrameRange(), step: 1)
                                        .padding()
                                        .frame(width: geom.size.height)
                                        .rotated(.degrees(90))

                                    Spacer()
                                }
                            }

                            KFImage(self.store.timeComicFrames[Int(currentFrame)].getURL())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: self.getImageWidthHeight(geom).width, height: self.getImageWidthHeight(geom).height)
                                .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                                    if abs(value.translation.width) + abs(value.translation.height) < 50 {
                                        // Probably a tap
                                        let isLeftTap = value.location.x < self.getImageWidthHeight(geom).width / 2

                                        if isLeftTap {
                                            self.currentFrame = getFrameRange().clamp(self.currentFrame - 1)
                                        } else {
                                            self.currentFrame = getFrameRange().clamp(self.currentFrame + 1)
                                        }
                                    } else {
                                        self.currentFrame = getFrameRange().clamp(value.translation.width < 0 ? self.currentFrame + 1 : self.currentFrame - 1)
                                    }
                                })
                                .animation(.none)
                                .transition(.identity)

                            if self.isLandscape(geom) {
                                HStack {
                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text("\(Int(currentFrame + 1)) / \(store.timeComicFrames.count)")
                                            .font(.headline)
                                            .animation(.none)
                                            .transition(.identity)

                                        Spacer()

                                        if !self.areAllFramesCached {
                                            Button(action: {
                                                self.cacheImages()
                                            }) {
                                                Text("Load all frames")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !self.isLandscape(geom) {
                            Slider(value: $currentFrame, in: getFrameRange(), step: 1)

                            Spacer()

                            HStack {
                                Spacer()

                                if !self.areAllFramesCached {
                                    Button(action: {
                                        self.cacheImages()
                                    }) {
                                        Text("Load all frames")
                                    }.padding()
                                }
                            }
                        }
                    }
                }
                .padding()
            } else {
                EmptyView()
            }
        }
        .animation(.default)
        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
        .onAppear {
            self.handleAppear()
        }
    }
}

struct SpecialComicViewer: View {
    var id: Int

    var body: some View {
        if id == 1190 {
            TimeComicViewer()
        }
    }
}

struct SpecialComicViewer_Previews: PreviewProvider {
    static var previews: some View {
        SpecialComicViewer(id: 1190)
    }
}
