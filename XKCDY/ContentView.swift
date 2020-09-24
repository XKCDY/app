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
    @EnvironmentObject private var store: Store
    @State private var scrollDirection: ScrollDirection = .up
    @State private var showProAlert = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var userSettings = UserSettings()
    private var foregroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    func hidePager() {
        store.showPager = false
    }

    func handleComicOpen() {
        store.showPager = true
    }

    func handleShowProAlert() {
        let FIVE_MINUTES_IN_MS = 5 * 60 * 1000

        if !userSettings.showedProAlert && !userSettings.isSubscribedToPro && userSettings.timeSpentInApp > FIVE_MINUTES_IN_MS {
            self.showProAlert = true
            userSettings.showedProAlert = true
        }
    }

    func handleProDetailsOpen() {
        self.store.showSettings = true
    }

    func handleShuffleButtonPress() {
        self.store.shuffle {
            handleComicOpen()
        }
    }

    var body: some View {
        ZStack {
            if self.store.filteredComics.count > 0 {
                ComicsGridView(onComicOpen: self.handleComicOpen, hideCurrentComic: self.store.showPager, scrollDirection: self.$scrollDirection).edgesIgnoringSafeArea(.bottom)
            } else if self.store.searchText == "" && self.store.filteredComics.count == 0 {
                if self.store.selectedPage == .favorites {
                    Text("Go make some new favorites!").font(Font.body.bold()).foregroundColor(.secondary)
                } else if self.store.selectedPage == .unread {
                    Text("You're all caught up!").font(Font.body.bold()).foregroundColor(.secondary)
                }
            }

            if self.store.searchText != "" && self.store.filteredComics.count == 0 {
                Text("No results were found.").font(Font.body.bold()).foregroundColor(.secondary)
            }

            VStack {
                FloatingButtons(isSearching: self.$isSearching, onShuffle: self.handleShuffleButtonPress)
                    .padding()
                    .opacity(self.scrollDirection == .up || self.store.searchText != "" ? 1 : 0)
                    .animation(.default)
                    .sheet(isPresented: self.$store.showSettings) {
                        SettingsSheet(onDismiss: {
                            self.store.showSettings = false
                        })
                    }

                Spacer()

                FloatingNavBarView()
                    .animation(.spring())
            }

            if self.store.showPager {
                ComicPager(onHide: self.hidePager).onAppear(perform: handleShowProAlert)
            }

            if self.store.filteredComics.count == 0 && self.store.searchText == "" && self.store.selectedPage == .all {
                FortuneLoader()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(self.colorScheme == .dark ? Color.black : Color.white)
            }
        }
        .alert(isPresented: self.$showProAlert) {
            Alert(title: Text("Enjoying XKCDY?"), message: Text("Consider upgrading to XKCDY Pro for a few perks and to help support development!"), primaryButton: .default(Text("More Details"), action: self.handleProDetailsOpen), secondaryButton: .default(Text("Don't show this again")))
        }
    }
}
