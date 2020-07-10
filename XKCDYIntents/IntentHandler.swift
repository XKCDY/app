//
//  IntentHandler.swift
//  XKCDYIntents
//
//  Created by Max Isom on 7/9/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Intents
import RealmSwift

class IntentHandler: INExtension {
    func configureRealm() {
        // Set Realm file location
        let realmFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.maxisom.XKCDY")!
            .appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration.fileURL = realmFileURL
    }

    override func handler(for intent: INIntent) -> Any {
        configureRealm()

        if intent is GetComicIntent {
            return GetComicIntentHandler()
        } else if intent is GetLatestComicIntent {
            return GetLatestComicIntentHandler()
        }

        return GetComicIntentHandler()
    }

}

extension Comic {
    func toIntentResponse() -> ComicSiri {
        let comic = ComicSiri(identifier: String(id), display: title)

        comic.publishedAt = Calendar.current.dateComponents([.year, .month, .day], from: publishedAt)
        comic.title = title
        comic.transcript = transcript
        comic.alt = alt
        comic.sourceUrl = sourceURL

        if let imgs = imgs {
            if let x2 = imgs.x2 {
                comic.imageUrl = x2.url
            } else if let x1 = imgs.x1 {
                comic.imageUrl = x1.url
            }
        }

        return comic
    }
}
