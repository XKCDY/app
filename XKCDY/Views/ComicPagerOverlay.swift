//
//  ComicPagerOverlay.swift
//  XKCDY
//
//  Created by Max Isom on 7/17/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift
import StoreKit
import class Kingfisher.ImageCache

enum ActiveSheet {
    case share, details
}

struct ButtonBarItem: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 24))
            .padding(.horizontal)
            .padding(.top)
    }
}

struct ComicPagerOverlay: View {
    var comic: Comic
    @Binding var showSheet: Bool
    @Binding var activeSheet: ActiveSheet
    private var generator = UIImpactFeedbackGenerator()
    @State private var imageToShare: UIImage?
    @EnvironmentObject var store: Store
    var onShuffle: () -> Void

    init(comic: Comic, showSheet: Binding<Bool>, activeSheet: Binding<ActiveSheet>, onShuffle: @escaping () -> Void) {
        self.comic = comic
        self._showSheet = showSheet
        self._activeSheet = activeSheet
        self.onShuffle = onShuffle
        self.generator.prepare()
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

                HStack {
                    Button(action: self.openShareSheet) {
                        Image(systemName: "square.and.arrow.up").modifier(ButtonBarItem())
                    }

                    Button(action: {
                        self.activeSheet = .details
                        self.showSheet = true
                    }) {
                        Image(systemName: "info.circle.fill").modifier(ButtonBarItem())
                    }

                    HStack {
                        Spacer()

                        ZStack {
                            Image(systemName: "heart.fill")
                                .opacity(self.comic.isFavorite ? 1 : 0)
                                .animation(.none)
                                .scaleEffect(self.comic.isFavorite ? 1 : 0)
                                .foregroundColor(.red)

                            Image(systemName: "heart")
                                .opacity(self.comic.isFavorite ? 0 : 1)
                                .animation(.none)
                                .scaleEffect(self.comic.isFavorite ? 0 : 1)
                                .foregroundColor(.accentColor)
                        }
                        .modifier(ButtonBarItem())
                        .scaleEffect(self.comic.isFavorite ? 1.1 : 1)
                        .animation(.interpolatingSpring(stiffness: 180, damping: 15))

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.generator.impactOccurred()

                        let realm = try! Realm()

                        try! realm.write {
                            self.comic.isFavorite = !self.comic.isFavorite
                        }

                        // Request review if appropriate
                        let numberOfFavoritedComics = realm.objects(Comic.self).filter {$0.isFavorite}.count

                        if numberOfFavoritedComics == 2 {
                            SKStoreReviewController.requestReview()
                        }
                    }

                    // Invisible icon for padding
                    Image(systemName: "info.circle.fill").modifier(ButtonBarItem()).hidden()

                    Button(action: self.onShuffle) {
                        Image(systemName: "shuffle").modifier(ButtonBarItem())
                    }
                }
                .padding()
                .padding(.bottom, geom.safeAreaInsets.bottom)
                .background(Blur())
            }
            .edgesIgnoringSafeArea(.top)
            .edgesIgnoringSafeArea(.horizontal)
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
        ComicPagerOverlay(comic: .getSample(), showSheet: .constant(false), activeSheet: .constant(.details), onShuffle: {
            print("shuffling")
        }).colorScheme(.dark)
    }
}
