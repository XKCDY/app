//
//  GetComicIntentHandler.swift
//  XKCDYIntents
//
//  Created by Max Isom on 7/9/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import RealmSwift

class GetComicIntentHandler: NSObject, GetComicIntentHandling {
    func handle(intent: GetComicIntent, completion: @escaping (GetComicIntentResponse) -> Void) {
        // Update store
        let store = Store()

        store.partialRefetchComics { _ in
            let comicId = intent.comicId!.intValue

            let realm = try! Realm()

            let savedComic = realm.object(ofType: Comic.self, forPrimaryKey: comicId)

            let response = GetComicIntentResponse(code: .success, userActivity: nil)

            response.comic = savedComic?.toIntentResponse()

            completion(response)
        }
    }

    func resolveComicId(for intent: GetComicIntent, with completion: @escaping (GetComicComicIdResolutionResult) -> Void) {
        var result: GetComicComicIdResolutionResult = .unsupported()

        defer {completion(result) }

        if let id = intent.comicId?.intValue {
            result = GetComicComicIdResolutionResult.success(with: id)
        }
    }

}
