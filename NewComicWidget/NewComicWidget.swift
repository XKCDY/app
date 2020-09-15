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

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LastComicEntry {
        LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: context.family)
    }

    func configureRealm() {
        // Use shared Realm directory
        let realmFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.maxisom.XKCDY")!
            .appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration.fileURL = realmFileURL
    }

    func getEntry(family: WidgetFamily, completion: @escaping (LastComicEntry) -> Void) {
        var comic: Comic = .getTallSample()

        self.configureRealm()

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

            let entry = LastComicEntry(date: Date(), comic: comic, uiImage: image, family: family)

            completion(entry)
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (LastComicEntry) -> Void) {
        getEntry(family: context.family) {
            completion($0)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        self.configureRealm()

        Store(isLive: false).partialRefetchComics { _ in
            getEntry(family: context.family) { entry in
                let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!

                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

                completion(timeline)
            }
        }
    }
}

struct LastComicEntry: TimelineEntry {
    var date: Date
    let comic: Comic
    let uiImage: UIImage
    let family: WidgetFamily

    var relevance: TimelineEntryRelevance? {
        TimelineEntryRelevance(score: comic.isRead ? 0 : 70)
    }
}

struct NewComicWidgetEntryView: View {
    var entry: Provider.Entry

    func getRatioOfComic() -> Float {
        if let x2Ratio = entry.comic.imgs?.x2?.ratio {
            return x2Ratio
        }

        if let x1Ratio = entry.comic.imgs?.x1?.ratio {
            return x1Ratio
        }

        return 0
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("#\(String(entry.comic.id))")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(entry.comic.isRead ? Color.gray : Color.green)
                .cornerRadius(8)

            Text(entry.comic.title).lineLimit(1)

            if entry.family == .systemSmall {
                Text(entry.comic.alt).font(.caption)
            }

            Spacer(minLength: 0)

            if entry.family != .systemSmall {
                Spacer()

                GeometryReader { geom in
                    if getRatioOfComic() < 1.5 {
                        Image(uiImage: entry.uiImage).resizable().frame(width: geom.size.width, height: geom.size.width / CGFloat(getRatioOfComic()))
                    } else {
                        Image(uiImage: entry.uiImage).resizable().frame(width: CGFloat(getRatioOfComic()) * geom.size.height, height: geom.size.height)
                    }
                }
            }
        }
        .padding()
        .foregroundColor(.white)
        .widgetURL(URL(string: "xkcdy://comics/\(entry.comic.id)"))
    }
}

@main
struct NewComicWidget: Widget {
    let kind: String = "NewComicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NewComicWidgetEntryView(entry: entry).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .configurationDisplayName("Latest XKCD Comic")
        .description("Displays the latest XKCD comic.")
    }
}

struct NewComicWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemSmall))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemMedium))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemLarge))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
