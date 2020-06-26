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

final class Store: ObservableObject {
    var positions: [Int: CGRect] = [Int: CGRect]()
    @Published var currentComicId = 100
    @Published var shouldBlurHeader = true
    @Published var filteredComics: Results<ComicObject>
    
    init() {
        let realm = try! Realm()
        filteredComics = realm.objects(ComicObject.self)
    }
    
    func updatePosition(for id: Int, at: CGRect) {
        positions[id] = at
    }
    
    func refetchComics(callback: (() -> ())? = nil) {
        let realm = try! Realm()
        let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)
        
        xkcd.getAllComics { c in
            guard let c = c else {
                return
            }
            
            let realm = try! Realm()
            
            try! realm.write {
                for comic in c {
                    let updatedComic = comic.toObject()
                    
                    if let currentlySavedComic = realm.object(ofType: ComicObject.self, forPrimaryKey: updatedComic.id) {
                        updatedComic.isFavorite = currentlySavedComic.isFavorite
                        updatedComic.isRead = currentlySavedComic.isRead
                    }
                    
                    realm.add(updatedComic, update: .modified)
                    
                    // TODO: make more efficient
                    if comics!.comics.filter("id == %@", updatedComic.id).count == 0 {
                        comics!.comics.append(updatedComic)
                    }
                }
                
                callback?()
            }
        }
    }
    
    func partialRefetchComics() {
        
    }
}
