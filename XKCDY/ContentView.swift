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

struct TestPage: Equatable {
    var id: Int
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedPage = "Home"
    @EnvironmentObject var store: Store
    @State private var pagerOffset: CGPoint = .zero
    @State private var showPager = false
    @State private var isPagerHidden = false
    @EnvironmentObject var comics: RealmSwift.List<ComicObject>
    
    func hidePager() -> Void {
        print("hiding")
        showPager = false
    }
    
    func handleComicOpen() -> Void {
        showPager = true
    }
    
    func filteredCollection() -> AnyRealmCollection<ComicObject> {
        if self.selectedPage == "Favorites" {
            return AnyRealmCollection(self.comics.filter("isFavorite == true"))
        } else if self.selectedPage == "Search" && searchText != "" {
            return AnyRealmCollection(self.comics.filter("title CONTAINS[c] %@", searchText))
        }

        return AnyRealmCollection(self.comics)
    }

    var body: some View {
        GeometryReader { geom in
            ZStack {
                ComicsGridView(onComicOpen: self.handleComicOpen, hideCurrentComic: self.showPager, comics: self.filteredCollection().freeze()).edgesIgnoringSafeArea(.bottom)

                VStack {
                    if (self.selectedPage != "Search") {
                        Spacer()
                    }

                    FloatingNavBarView(pages: ["Home", "Favorites", "Search"], selected: self.$selectedPage, searchText: self.$searchText)
                        .animation(.spring())

                    if (self.selectedPage == "Search") {
                        Spacer()
                    }
                }

                Rectangle().fill(Color.clear)
                .background(Blur(style: .regular))
                .frame(width: geom.size.width, height: geom.safeAreaInsets.top)
                .position(x: geom.size.width / 2, y: -geom.safeAreaInsets.top / 2)
                    .opacity(self.store.shouldBlurHeader ? 1 : 0)

                if (self.showPager) {
                    ComicPager(onHide: self.hidePager)
                }
            }
        }
        .onAppear {
            self.store.refetchComics()
        }
    }
}
