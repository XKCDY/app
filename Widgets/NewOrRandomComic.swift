//
//  NewOrRandomComic.swift
//  Widgets
//
//  Created by Max Isom on 10/1/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import WidgetKit
import SwiftUI
import RealmSwift
import class Kingfisher.KingfisherManager
import protocol Kingfisher.Resource

struct NewOrRandomComicWidgetProvider: IntentTimelineProvider {
    typealias Entry = ComicEntry
    typealias Intent = ViewLatestComicIntent

    private func getRandomComic() -> Comic? {
        Helpers.configureRealm()

        let realm = try! Realm()

        let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

        return comics?.comics.randomElement()
    }

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

    func getRandomTimeline(context: Context, completion: @escaping (Timeline<ComicEntry>) -> Void) {
        var entries: [Entry] = []

        let imageCacheGroup = DispatchGroup()

        let currentDate = Date()

        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!

            if let randomComic = self.getRandomComic() {
                imageCacheGroup.enter()

                // Cache image
                KingfisherManager.shared.retrieveImage(with: randomComic.getBestImageURL()!) { result in
                    guard case .success(let imageResult) = result else {
                        imageCacheGroup.leave()
                        return
                    }

                    let entry = ComicEntry(date: entryDate, comic: randomComic, uiImage: imageResult.image, family: context.family, shouldBlur: false)

                    entries.append(entry)

                    imageCacheGroup.leave()
                }
            }
        }

        imageCacheGroup.notify(queue: .main) {
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }

    func getTimeline(for configuration: ViewLatestComicIntent, in context: Context, completion: @escaping (Timeline<ComicEntry>) -> Void) {
        Helpers.configureRealm()

        Store(isLive: false).partialRefetchComics { _ in
            let realm = try! Realm()

            if !(realm.object(ofType: Comics.self, forPrimaryKey: 0)?.comics.sorted(byKeyPath: "id").last?.isRead ?? true) {
                // Latest comic is unread, show it
                getEntry(family: context.family, configuration: configuration) { entry in
                    let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!

                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

                    completion(timeline)
                }
            } else {
                // Show random comics
                getRandomTimeline(context: context) { timeline in
                    completion(timeline)
                }
            }
        }
    }
}

struct NewOrRandomComicWidget: Widget {
    let kind: String = "NewOrRandomComicWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ViewLatestComicIntent.self, provider: NewOrRandomComicWidgetProvider()) { entry in
            Group {
                if entry.family == .systemSmall {
                    SmallComicWidgetView(entry: entry)
                } else {
                    LargeComicWidgetView(entry: entry)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .configurationDisplayName("Latest or random comic")
        .description("Displays the latest comic if unread, otherwise displays a random comic.")
    }
}
