//
//  ContentView.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import RealmSwift
import ASCollectionView
import struct Kingfisher.KFImage

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedPage = "Home"
    @EnvironmentObject var store: Store
    @State private var pagerOffset: CGPoint = .zero
    @State private var showPager = false
    @State private var isPagerHidden = false
    @EnvironmentObject var comics: RealmSwift.List<Comic>
    let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    func hidePager() {
        print("hiding")
        showPager = false
    }

    func handleComicOpen() {
        showPager = true
    }

    func wrapAndSort(list: Results<Comic>) -> Results<Comic> {
        return AnyRealmCollection(list).freeze().sorted(byKeyPath: "id", ascending: false)
    }

    func filteredCollection() -> Results<Comic> {
        if self.selectedPage == "Favorites" {
            return wrapAndSort(list: self.comics.filter("isFavorite == true"))
        } else if self.selectedPage == "Search" && searchText != "" {
            if let searchId = Int(searchText) {
                return wrapAndSort(list: self.comics.filter("id == %@", searchId))
            }

            return wrapAndSort(list: self.comics.filter("title CONTAINS[c] %@ OR alt CONTAINS %@ OR transcript CONTAINS %@", searchText, searchText, searchText))
        }

        return AnyRealmCollection(self.comics).freeze().sorted(byKeyPath: "id", ascending: false)
    }

    func refetchComics() {
        DispatchQueue.global(qos: .background).async {
            self.store.partialRefetchComics()
        }
    }

    var body: some View {
        GeometryReader { geom in
            ZStack {
                ComicsGridView(onComicOpen: self.handleComicOpen, hideCurrentComic: self.showPager, comics: self.filteredCollection()).edgesIgnoringSafeArea(.bottom)

                VStack {
                    if self.selectedPage != "Search" {
                        Spacer()
                    }

                    FloatingNavBarView(pages: ["Home", "Favorites", "Search"], selected: self.$selectedPage, searchText: self.$searchText)
                        .animation(.spring())

                    if self.selectedPage == "Search" {
                        Spacer()
                    }
                }

                if !self.showPager {
                    Rectangle().fill(Color.clear)
                        .background(Blur(style: .regular))
                        .frame(width: geom.size.width, height: geom.safeAreaInsets.top)
                        .position(x: geom.size.width / 2, y: -geom.safeAreaInsets.top / 2)
                        .opacity(self.store.shouldBlurHeader ? 1 : 0)
                }

                if self.showPager {
                    ComicPager(onHide: self.hidePager, comics: self.filteredCollection())
                }
            }
        }
        .onAppear(perform: refetchComics)
        .onReceive(foregroundPublisher) { _ in
            self.refetchComics()
        }
    }
}
