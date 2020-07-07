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

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

class BindableResults<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
    var results: Results<Element>
    private var token: NotificationToken!

    init(results: Results<Element>) {
        self.results = results
        lateInit()
    }

    func lateInit() {
        token = results.observe { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        token.invalidate()
    }
}

enum StoreError: Error {
    case other
    case api
}

final class Store: ObservableObject {
    var positions: [Int: CGRect] = [Int: CGRect]()
    @Published var currentComicId = 100
    @Published var shouldBlurHeader = true

    func updatePosition(for id: Int, at: CGRect) {
        positions[id] = at
    }

    func updateDatabaseFrom(results: [ComicResponse], callback: () -> Void) {
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

            callback()
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
