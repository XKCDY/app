//
//  RandomComicWidget.swift
//  Widgets
//
//  Created by Max Isom on 9/20/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import WidgetKit
import RealmSwift
import class Kingfisher.KingfisherManager

struct RandomComicWidgetProvider: TimelineProvider {
    typealias Entry = ComicEntry

    private func getRandomComic() -> Comic? {
        Helpers.configureRealm()

        let realm = try! Realm()

        let comics = realm.object(ofType: Comics.self, forPrimaryKey: 0)

        return comics?.comics.randomElement()
    }

    func placeholder(in context: Context) -> ComicEntry {
        ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: context.family, shouldBlur: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComicEntry) -> Void) {
        let comic = self.getRandomComic() ?? .getTallSample()

        KingfisherManager.shared.retrieveImage(with: comic.getBestImageURL()!) { result in
            guard case .success(let imageResult) = result else { return }

            let entry = ComicEntry(date: Date(), comic: comic, uiImage: imageResult.image, family: context.family, shouldBlur: false)

            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComicEntry>) -> Void) {
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
}

struct RandomComicWidget: Widget {
    let kind = "RandomComicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RandomComicWidgetProvider()) { entry in
            Group {
                if entry.family == .systemSmall {
                    SmallComicWidgetView(entry: entry)
                } else {
                    LargeComicWidgetView(entry: entry)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .configurationDisplayName("Random Comic")
        .description("Displays a random XKCD comic.")
    }
}
