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
    @Binding var showSheet: Bool
    @Binding var activeSheet: ActiveSheet
    private var generator = UIImpactFeedbackGenerator()
    @State private var imageToShare: UIImage?
    @State private var showingShareOptionsSheet = false
    @EnvironmentObject var store: Store
    var onShuffle: () -> Void
    var onClose: () -> Void
    @ObservedObject private var userSettings = UserSettings()

    init(showSheet: Binding<Bool>, activeSheet: Binding<ActiveSheet>, onShuffle: @escaping () -> Void, onClose: @escaping () -> Void) {
        self._showSheet = showSheet
        self._activeSheet = activeSheet
        self.onShuffle = onShuffle
        self.onClose = onClose
        self.generator.prepare()
    }

    private func shareImage(withDetails: Bool) {
        if withDetails {
            SharableComicView(comic: self.store.comic).asImage { image in
                self.imageToShare = image

                self.activeSheet = .share
                self.showSheet = true
            }
        } else {
            ImageCache.default.retrieveImage(forKey: self.store.comic.getBestImageURL()!.absoluteString) { result in
                switch result {
                case .success(let value):
                    self.imageToShare = value.image

                    self.activeSheet = .share
                    self.showSheet = true

                case .failure:
                    return
                }
            }
        }
    }

    private func shareURL() {
        self.imageToShare = nil
        self.activeSheet = .share
        self.showSheet = true
    }

    var body: some View {
        GeometryReader { geom in
            VStack {
                ZStack {
                    HStack {
                        Button(action: self.onClose) {
                            Image(systemName: "chevron.left").font(.system(size: 24)).padding(.leading)
                        }

                        VStack {
                            Text(self.store.comic.title)
                                .font(.title)
                                .multilineTextAlignment(.center)

                            if self.userSettings.showComicIdInPager {
                                Text("#\(self.store.comic.id)").font(.headline)
                            }
                        }.frame(maxWidth: .infinity)

                        Image(systemName: "chevron.left").font(.system(size: 24)).padding(.trailing).hidden()
                    }
                    .padding()
                    .padding(.top, geom.safeAreaInsets.top)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Blur())
                    .animation(.none)
                }

                Spacer()

                VStack {
                    if self.userSettings.showAltInPager {
                        Text(self.store.comic.alt)
                            .multilineTextAlignment(.center)
                            // Prevent from overlapping with notch
                            .padding(.trailing, geom.safeAreaInsets.trailing)
                            .padding(.leading, geom.safeAreaInsets.leading)
                    }

                    HStack {
                        Button(action: {
                            self.showingShareOptionsSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up").modifier(ButtonBarItem())
                        }
                        .actionSheet(isPresented: self.$showingShareOptionsSheet) {
                            ActionSheet(title: Text("What do you want to share?"), buttons: [
                                .default(Text("Share image"), action: {
                                    self.shareImage(withDetails: false)
                                }),
                                .default(Text("Share image with details"), action: {
                                    self.shareImage(withDetails: true)
                                }),
                                .default(Text("Share link to comic"), action: self.shareURL),
                                .cancel()
                            ])
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
                                    .opacity(self.store.comic.isFavorite ? 1 : 0)
                                    .animation(.none)
                                    .scaleEffect(self.store.comic.isFavorite ? 1 : 0)
                                    .foregroundColor(.red)

                                Image(systemName: "heart")
                                    .opacity(self.store.comic.isFavorite ? 0 : 1)
                                    .animation(.none)
                                    .scaleEffect(self.store.comic.isFavorite ? 0 : 1)
                                    .foregroundColor(.accentColor)
                            }
                            .modifier(ButtonBarItem())
                            .scaleEffect(self.store.comic.isFavorite ? 1.1 : 1)
                            .animation(.interpolatingSpring(stiffness: 180, damping: 15))

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.generator.impactOccurred()

                            let realm = try! Realm()

                            try! realm.write {
                                self.store.comic.isFavorite = !self.store.comic.isFavorite
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
                }
                .padding()
                .padding(.bottom, geom.safeAreaInsets.bottom)
                .background(Blur())
            }
            .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: self.$showSheet) {
            if self.activeSheet == .share {
                if self.imageToShare == nil {
                    URLActivityViewController(url: self.store.comic.sourceURL!)
                } else {
                    UIImageActivityViewController(uiImage: self.imageToShare!, title: self.store.comic.title, url: self.store.comic.sourceURL!)
                }
            } else if self.activeSheet == .details {
                ComicDetailsSheet(comic: self.store.comic, onDismiss: {
                    self.showSheet = false
                })
            }
        }
    }
}

struct ComicPagerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ComicPagerOverlay(showSheet: .constant(false), activeSheet: .constant(.details), onShuffle: {
            print("shuffling")
        }, onClose: {
            print("closing")
        }).colorScheme(.dark)
    }
}
