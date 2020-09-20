//
//  NewComicWidget.swift
//  NewComicWidget
//
//  Created by Max Isom on 8/26/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import WidgetKit
import SwiftUI
import RealmSwift
import class Kingfisher.KingfisherManager
import protocol Kingfisher.Resource

struct LatestComicWidgetProvider: IntentTimelineProvider {
    typealias Entry = ComicEntry
    typealias Intent = ViewLatestComicIntent

    func placeholder(in context: Context) -> ComicEntry {
        ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: context.family, shouldBlur: false)
    }

    func getEntry(family: WidgetFamily, configuration: ViewLatestComicIntent, completion: @escaping (ComicEntry) -> Void) {
        var comic: Comic = .getTallSample()

        Helpers.configureRealm()

        let realm = try! Realm()

        if let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0) {
            if let savedComic = comics.comics.sorted(byKeyPath: "id").last {
                comic = savedComic.freeze()
            }
        }

        KingfisherManager.shared.retrieveImage(with: comic.getBestImageURL()!) { result in
            var image = UIImage()

            switch result {
            case .success(let imageResult):
                image = imageResult.image
            case .failure:
                return
            }

            let entry = ComicEntry(date: Date(), comic: comic, uiImage: image, family: family, shouldBlur: configuration.shouldBlurUnread == .some(1) && !comic.isRead)

            completion(entry)
        }
    }

    func getSnapshot(for configuration: ViewLatestComicIntent, in context: Context, completion: @escaping (ComicEntry) -> Void) {
        getEntry(family: context.family, configuration: configuration) {
            completion($0)
        }
    }

    func getTimeline(for configuration: ViewLatestComicIntent, in context: Context, completion: @escaping (Timeline<ComicEntry>) -> Void) {
        Helpers.configureRealm()

        Store(isLive: false).partialRefetchComics { _ in
            getEntry(family: context.family, configuration: configuration) { entry in
                let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!

                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

                completion(timeline)
            }
        }
    }
}

struct NewComicWidget: Widget {
    let kind: String = "NewComicWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ViewLatestComicIntent.self, provider: LatestComicWidgetProvider()) { entry in
            Group {
                if entry.family == .systemSmall {
                    SmallComicWidgetView(entry: entry)
                } else {
                    LargeComicWidgetView(entry: entry)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .configurationDisplayName("Latest XKCD Comic")
        .description("Displays the latest XKCD comic.")
    }
}
