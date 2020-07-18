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

struct ContentView: View {
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var selectedPage: Page = .all
    @EnvironmentObject var store: Store
    @State private var pagerOffset: CGPoint = .zero
    @State private var isPagerHidden = false
    @EnvironmentObject var comics: RealmSwift.List<Comic>
    let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    @State private var scrollDirection: ScrollDirection = .up
    @State private var showSettings = false

    func hidePager() {
        store.showPager = false
    }

    func handleComicOpen() {
        store.showPager = true
    }

    func filteredCollection() -> Results<Comic> {
        var results = AnyRealmCollection(self.comics)

        if searchText != "" {
            if let searchId = Int(searchText) {
                results = AnyRealmCollection(results.filter("id == %@", searchId))
            } else {
                results = AnyRealmCollection(results.filter("title CONTAINS[c] %@ OR alt CONTAINS[c] %@ OR transcript CONTAINS[c] %@", searchText, searchText, searchText))
            }
        }

        if selectedPage == .favorites {
            results = AnyRealmCollection(results.filter("isFavorite == true"))
        }

        return results.freeze().sorted(byKeyPath: "id", ascending: false)
    }

    func refetchComics() {
        DispatchQueue.global(qos: .background).async {
            self.store.partialRefetchComics()
        }
    }

    var body: some View {
        ZStack {
            ComicsGridView(onComicOpen: self.handleComicOpen, hideCurrentComic: self.store.showPager, scrollDirection: self.$scrollDirection, comics: self.filteredCollection()).edgesIgnoringSafeArea(.bottom)

            VStack {
                FloatingButtons(isSearching: self.$isSearching, searchText: self.$searchText, onOpenSettings: {
                    self.showSettings = true
                })
                    .padding()
                    .opacity(self.scrollDirection == .up || self.searchText != "" ? 1 : 0)
                    .animation(.default)
                    .sheet(isPresented: self.$showSettings) {
                        SettingsSheet(onDismiss: {
                            self.showSettings = false
                        })
                }

                Spacer()

                FloatingNavBarView(selected: self.$selectedPage)
                    .animation(.spring())
            }

            if self.store.showPager {
                ComicPager(onHide: self.hidePager, comics: self.filteredCollection())
            }
        }
        .onAppear(perform: refetchComics)
        .onReceive(foregroundPublisher) { _ in
            self.refetchComics()
        }
    }
}
