//
//  GetLatestComicIntentHandler.swift
//  XKCDYIntents
//
//  Created by Max Isom on 7/10/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import RealmSwift

class GetLatestComicIntentHandler: NSObject, GetLatestComicIntentHandling {
    func handle(intent: GetLatestComicIntent, completion: @escaping (GetLatestComicIntentResponse) -> Void) {
        // Update store
        let store = Store()

        store.partialRefetchComics { _ in
            let realm = try! Realm()

            let savedComic = realm.objects(Comic.self).sorted(byKeyPath: "id", ascending: false).first

            let response = GetLatestComicIntentResponse(code: .success, userActivity: nil)

            response.comic = savedComic?.toIntentResponse()

            completion(response)
        }
    }
}
