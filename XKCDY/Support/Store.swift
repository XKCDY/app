//
//  Store.swift
//  DCKX
//
//  Created by Max Isom on 5/31/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift
import Combine
import class Kingfisher.ImagePrefetcher

enum StoreError: Error {
    case other
    case api
}

enum Page: String, CaseIterable, Hashable, Identifiable {
    case all
    case unread
    case favorites

    var name: String {
        "\(self)".map { $0.isUppercase ? " \($0)" : "\($0)" }.joined().capitalized
    }

    var id: Page {self}
}

final class Store: ObservableObject {
    var positions: [Int: CGRect] = [Int: CGRect]()
    var isLive: Bool
    @Published var currentComicId: Int?
    var comic: Comic {
        try! Realm().object(ofType: Comic.self, forPrimaryKey: self.currentComicId)!
    }
    @Published var debouncedCurrentComicId: Int?
    @Published var showPager = false
    @Published var showSettings = false
    @Published var selectedPage: Page = .all {
        willSet {
            self.handlePageChange(newValue)
        }
        didSet {
            self.updateFilteredComics()
        }
    }
    @Published var searchText = "" {
        didSet {
            self.updateFilteredComics()
        }
    }
    @Published var currentFavoriteIds: [Int] = []
    @Published var filteredComics: Results<Comic> {
        didSet {
            self.addFrozenObserver()
            self.cacheNextShuffleResult()
        }
    }
    @Published var timeComicFrames: AnyRealmCollection<TimeComicFrame>
    @Published var frozenFilteredComics: Results<Comic>

    @ObservedObject private var userSettings = UserSettings()
    @ObservedObject private var comics: RealmSwift.List<Comic>

    private var nextShuffleResultId: Int?

    private var comicToken: NotificationToken?
    private var comicsToken: NotificationToken?
    private var disposables = Set<AnyCancellable>()

    init(isLive: Bool) {
        self.isLive = isLive

        let realm = try! Realm()
        var comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

        if comics == nil {
            comics = try! realm.write { realm.create(Comics.self, value: []) }
        }

        self.comics = comics!.comics

        let initialComics = comics!.comics.sorted(byKeyPath: "id", ascending: false)
        self.filteredComics = initialComics

        self.frozenFilteredComics = initialComics.freeze().sorted(byKeyPath: "id", ascending: false)

        self.timeComicFrames = AnyRealmCollection(realm.objects(TimeComicFrame.self).sorted(byKeyPath: "frameNumber", ascending: true))

        self.updateFilteredComics()
        self.addFrozenObserver()
        self.cacheNextShuffleResult()

        if self.isLive {
            DispatchQueue.main.async {
                self.$currentComicId
                    .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                    .assign(to: \.debouncedCurrentComicId, on: self)
                    .store(in: &self.disposables)
            }

            self.userSettings.objectWillChange.sink { _ in
                self.updateFilteredComics()
            }
            .store(in: &self.disposables)
        }
    }

    private func getOrCreateLastFilteredComicsInstance() -> LastFilteredComics {
        let realm = try! Realm()

        var filtered = realm.object(ofType: LastFilteredComics.self, forPrimaryKey: 0)

        if filtered == nil {
            filtered = try! realm.write { realm.create(LastFilteredComics.self, value: []) }
        }

        return filtered!
    }

    private func addFrozenObserver() {
        if self.isLive {
            self.comicsToken = self.filteredComics.observe { _ in
                self.frozenFilteredComics = self.filteredComics.freeze().sorted(byKeyPath: "id", ascending: false)
            }
        }
    }

    private func updateFilteredComics() {
        if !self.isLive {
            return
        }

        DispatchQueue.main.async {
            var results = self.comics.filter("TRUEPREDICATE")

            if !self.userSettings.showCOVIDComics {
                results = results.filter("NOT (id IN %@)", COVID_COMICS)
            }

            if self.searchText != "" {
                if let searchId = Int(self.searchText) {
                    results = results.filter("id == %@", searchId)
                } else {
                    results = results.filter("title CONTAINS[c] %@ OR alt CONTAINS[c] %@ OR transcript CONTAINS[c] %@", self.searchText, self.searchText, self.searchText)
                }
            }

            if self.selectedPage == .favorites {
                let lastFilteredComics = self.getOrCreateLastFilteredComicsInstance()

                let realm = try! Realm()

                try! realm.write {
                    lastFilteredComics.comics.removeAll()
                    lastFilteredComics.comics.append(objectsIn: results.filter("isFavorite == true"))
                }

                self.filteredComics = lastFilteredComics.comics.sorted(byKeyPath: "id", ascending: false)
            } else if self.selectedPage == .unread {
                let lastFilteredComics = self.getOrCreateLastFilteredComicsInstance()

                let realm = try! Realm()

                try! realm.write {
                    lastFilteredComics.comics.removeAll()
                    lastFilteredComics.comics.append(objectsIn: results.filter("isRead == false"))
                }

                self.filteredComics = lastFilteredComics.comics.sorted(byKeyPath: "id", ascending: false)
            } else {
                self.filteredComics = results.sorted(byKeyPath: "id", ascending: false)
            }
        }
    }

    private func cacheNextShuffleResult() {
        guard let randomComic = filteredComics.randomElement() else {
            return
        }

        if self.isLive {
            ImagePrefetcher(urls: [randomComic.getBestImageURL()!]).start()
        }

        self.nextShuffleResultId = randomComic.id
    }

    func shuffle(_ completion: () -> Void) {
        if let id = self.nextShuffleResultId {
            // Make sure last cache result is still in current view
            if self.filteredComics.filter({ $0.id == id }).count == 1 {
                self.currentComicId = id
                completion()
            }
        }

        self.cacheNextShuffleResult()
    }

    func handlePageChange(_ page: Page) {
        if page == .favorites {
            let realm = try! Realm()
            let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)
            self.currentFavoriteIds = comics!.comics.filter { $0.isFavorite }.map { $0.id }
        } else {
            self.currentFavoriteIds = []
        }

        self.showPager = false
    }

    func updatePosition(for id: Int, at: CGRect) {
        positions[id] = at
    }

    func updateDatabaseFrom(results: [ComicResponse], callback: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let realm = try! Realm()
            let storedComics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

            try! realm.write {
                for comic in results {
                    let updatedComic = comic.toObject()

                    if let currentlySavedComic = realm.object(ofType: Comic.self, forPrimaryKey: updatedComic.id) {
                        updatedComic.isFavorite = currentlySavedComic.isFavorite
                        updatedComic.isRead = currentlySavedComic.isRead
                    }

                    realm.add(updatedComic, update: .modified)

                    if storedComics!.comics.filter("id == %@", updatedComic.id).count == 0 {
                        storedComics!.comics.append(updatedComic)
                    }
                }
            }

            if results.count > 0 {
                self.updateFilteredComics()
            }

            DispatchQueue.main.async {
                callback()
            }
        }
    }

    func refetchComics(callback: ((Result<[Int], StoreError>) -> Void)? = nil) {
        API.getComics { result in
            switch result {
            case .success(let comics): do {
                self.updateDatabaseFrom(results: comics) {
                    callback?(.success(comics.map { $0.id }))
                }
            }
            case .failure: do {
                callback?(.failure(.api))
            }
            }
        }

        // Get frames for Time
        let realm = try! Realm()
        let storedFrames = realm.objects(TimeComicFrame.self)

        if storedFrames.count == 0 {
            XKCDTimeClient.getFrames { result in
                let realm = try! Realm()

                switch result {
                case .success(let frames):
                    try! realm.write {
                        for frame in frames {
                            if frame.getImageURL() != nil {
                                realm.create(TimeComicFrame.self, value: frame.toObject())
                            }
                        }
                    }
                case .failure:
                    return
                }
            }
        }
    }

    // Falls through to a full refetch if no comics are stored locally
    func partialRefetchComics(callback: ((Result<[Int], StoreError>) -> Void)? = nil) {
        let realm = try! Realm()

        guard let latestComic = realm.objects(Comic.self).sorted(byKeyPath: "id", ascending: false).first else {
            return self.refetchComics(callback: callback)
        }

        API.getComics(since: latestComic.id) { result in
            switch result {
            case .success(let comics): do {
                self.updateDatabaseFrom(results: comics) {
                    callback?(.success(comics.map { $0.id }))
                }
            }
            case .failure: do {
                callback?(.failure(.api))
            }
            }

        }
    }
}

extension ComicResponse {
    func toObject() -> Comic {
        let obj = Comic()

        obj.id = id
        obj.publishedAt = publishedAt
        obj.news = news
        obj.title = title
        obj.safeTitle = safeTitle
        obj.transcript = transcript
        obj.alt = alt
        obj.sourceURL = URL(string: sourceUrl)
        obj.explainURL = URL(string: explainUrl)
        obj.interactiveUrl = interactiveUrl != nil && interactiveUrl != "" ? URL(string: interactiveUrl!) : nil

        let images = ComicImages()

        for img in imgs {
            let saved = ComicImage()

            saved.height = img.height
            saved.width = img.width
            saved.ratio = img.ratio
            saved.url = URL(string: img.sourceUrl)!

            if img.size == "x1" {
                images.x1 = saved
            } else {
                images.x2 = saved
            }
        }

        obj.imgs = images

        return obj
    }
}
