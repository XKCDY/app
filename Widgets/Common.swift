//
//  Common.swift
//  Widgets
//
//  Created by Max Isom on 9/20/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import WidgetKit
import RealmSwift

struct ComicEntry: TimelineEntry {
    var date: Date
    let comic: Comic
    let uiImage: UIImage
    let family: WidgetFamily
    let shouldBlur: Bool

    var relevance: TimelineEntryRelevance? {
        TimelineEntryRelevance(score: comic.isRead ? 0 : 70)
    }
}

struct Helpers {
    static func configureRealm() {
        // Use shared Realm directory
        let realmFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.maxisom.XKCDY")!
            .appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration.fileURL = realmFileURL
    }
}
