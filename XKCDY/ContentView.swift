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
    private var oldFavorites: [Int] = []
    @EnvironmentObject private var store: Store
    @State private var pagerOffset: CGPoint = .zero
    @State private var isPagerHidden = false
    @EnvironmentObject var comics: RealmSwift.List<Comic>
    let foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    @State private var scrollDirection: ScrollDirection = .up
    @State private var showSettings = false
    @State private var showProAlert = false
    @State private var isLoadingFromScratch = false
    @Environment(\.colorScheme) private var colorScheme

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

        if self.store.selectedPage == .favorites {
            results = AnyRealmCollection(results.filter("isFavorite == true OR id IN %@", self.store.currentFavoriteIds))
        }

        return results.freeze().sorted(byKeyPath: "id", ascending: false)
    }

    func refetchComics() {
        if self.comics.count == 0 {
            self.isLoadingFromScratch = true
        }

        DispatchQueue.global(qos: .background).async {
            self.store.partialRefetchComics { _ in
                self.isLoadingFromScratch = false
            }
        }
    }

    func handleAppear() {
        self.refetchComics()
    }

    func handleShowProAlert() {
        let FIVE_MINUTES_IN_MS = 5 * 60 * 1000
        let settings = UserSettings()

        if !settings.showedProAlert && !settings.isSubscribedToPro && settings.timeSpentInApp > FIVE_MINUTES_IN_MS {
            self.showProAlert = true
            settings.showedProAlert = true
        }
    }

    func handleProDetailsOpen() {
        self.showSettings = true
    }

    var body: some View {
        ZStack {
            if self.filteredCollection().count > 0 {
                ComicsGridView(onComicOpen: self.handleComicOpen, hideCurrentComic: self.store.showPager, scrollDirection: self.$scrollDirection, comics: self.filteredCollection()).edgesIgnoringSafeArea(.bottom)
            } else if self.store.selectedPage == .favorites {
                Text("Go make some new favorites!").font(Font.body.bold()).foregroundColor(.secondary)
            }

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

                FloatingNavBarView()
                    .animation(.spring())
            }

            if self.store.showPager {
                ComicPager(onHide: self.hidePager, comics: self.filteredCollection())
                    .onAppear(perform: handleShowProAlert)
            }

            if self.isLoadingFromScratch {
                FortuneLoader()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(self.colorScheme == .dark ? Color.black : Color.white)
            }
        }
        .alert(isPresented: self.$showProAlert) {
            Alert(title: Text("Enjoying XKCDY?"), message: Text("Consider upgrading to XKCDY Pro for a few perks and to help support development!"), primaryButton: .default(Text("More Details"), action: self.handleProDetailsOpen), secondaryButton: .default(Text("Don't show this again")))
        }
        .onAppear(perform: handleAppear)
        .onReceive(foregroundPublisher) { _ in
            self.refetchComics()
        }
    }
}
