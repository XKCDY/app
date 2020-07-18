//
//  ComicPagerOverlay.swift
//  XKCDY
//
//  Created by Max Isom on 7/17/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift
import class Kingfisher.ImageCache

enum ActiveSheet {
    case share, details
}

struct ComicPagerOverlay: View {
    var comic: Comic
    private var generator = UIImpactFeedbackGenerator()
    @State private var imageToShare: UIImage?
    @State private var showSheet = false
    @State private var activeSheet: ActiveSheet = .details
    @EnvironmentObject var store: Store
    var onShuffle: () -> Void

    init(comic: Comic, onShuffle: @escaping () -> Void) {
        self.comic = comic
        self.onShuffle = onShuffle
    }

    private func openShareSheet() {
        let cache = ImageCache.default

        cache.retrieveImage(forKey: comic.getBestImageURL()!.absoluteString) { result in
            switch result {
            case .success(let value):
                self.imageToShare = value.image

            case .failure:
                return
            }

            self.activeSheet = .share
            self.showSheet = true
        }
    }

    var body: some View {
        GeometryReader { geom in
            VStack {
                ZStack {
                    Text(self.comic.title)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.top, geom.safeAreaInsets.top)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(Blur())
                        .animation(.none)
                }

                Spacer()

                VStack {
                    HStack {
                        Button(action: self.openShareSheet) {
                            Image(systemName: "square.and.arrow.up").font(.system(size: 24))
                        }

                        Rectangle().fill(Color.clear).frame(width: 12, height: 24)

                        Button(action: {
                            self.activeSheet = .details
                            self.showSheet = true
                            print("showing", self.showSheet)
                        }) {
                            Image(systemName: "info.circle.fill").font(.system(size: 24))
                        }

                        HStack {
                            Spacer()

                            Image(systemName: self.comic.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(self.comic.isFavorite ? .red : .blue)
                                .scaleEffect(self.comic.isFavorite ? 1.1 : 1)
                                .animation(.interactiveSpring())

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.generator.impactOccurred()

                            let realm = try! Realm()

                            try! realm.write {
                                self.comic.isFavorite = !self.comic.isFavorite
                            }
                        }

                        Rectangle().fill(Color.clear).frame(width: 36, height: 24)

                        Button(action: self.onShuffle) {
                            Image(systemName: "shuffle").font(.system(size: 24))
                        }
                    }.padding()
                }
                .padding()
                .background(Blur())
            }
            .edgesIgnoringSafeArea(.top)
        }
        .sheet(isPresented: self.$showSheet) {
            if self.activeSheet == .share {
                if self.imageToShare != nil {
                    SwiftUIActivityViewController(uiImage: self.imageToShare!, title: self.comic.title, url: self.comic.sourceURL!)
                }
            } else if self.activeSheet == .details {
                ComicDetailsSheet(comic: self.comic, onDismiss: {
                    self.showSheet = false
                })
            }
        }
    }
}

struct ComicPagerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ComicPagerOverlay(comic: .getSample(), onShuffle: {
            print("shuffling")
        }).colorScheme(.dark)
    }
}
