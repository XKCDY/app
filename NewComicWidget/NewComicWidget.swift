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

struct Provider: IntentTimelineProvider {
    typealias Entry = LastComicEntry
    typealias Intent = ViewLatestComicIntent

    func placeholder(in context: Context) -> LastComicEntry {
        LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: context.family, shouldBlur: false)
    }

    func configureRealm() {
        // Use shared Realm directory
        let realmFileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.maxisom.XKCDY")!
            .appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration.fileURL = realmFileURL
    }

    func getEntry(family: WidgetFamily, configuration: ViewLatestComicIntent, completion: @escaping (LastComicEntry) -> Void) {
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

            let entry = LastComicEntry(date: Date(), comic: comic, uiImage: image, family: family, shouldBlur: configuration.shouldBlurUnread == .some(1) && !comic.isRead)

            completion(entry)
        }
    }

    func getSnapshot(for configuration: ViewLatestComicIntent, in context: Context, completion: @escaping (LastComicEntry) -> Void) {
        getEntry(family: context.family, configuration: configuration) {
            completion($0)
        }
    }

    func getTimeline(for configuration: ViewLatestComicIntent, in context: Context, completion: @escaping (Timeline<LastComicEntry>) -> Void) {
        self.configureRealm()

        Store(isLive: false).partialRefetchComics { _ in
            getEntry(family: context.family, configuration: configuration) { entry in
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
    let shouldBlur: Bool

    var relevance: TimelineEntryRelevance? {
        TimelineEntryRelevance(score: comic.isRead ? 0 : 70)
    }
}

struct ComicBadgeHeader: View {
    var comic: Comic

    var body: some View {
        Text("#\(String(comic.id))")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(comic.isRead ? Color.gray : Color.green)
            .cornerRadius(8)
            .fixedSize(horizontal: true, vertical: false)
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
        ZStack {
            GeometryReader { geom in
                Image(uiImage: entry.uiImage).resizable().aspectRatio(contentMode: .fill).blur(radius: entry.shouldBlur ? 2 : 0)

                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.3), Color.white.opacity(0)]), startPoint: .top, endPoint: .bottom)).frame(width: geom.size.width, height: geom.size.height / 2)

                HStack {
                    ComicBadgeHeader(comic: entry.comic)

                    Text(entry.comic.title).font(.headline).lineLimit(1).foregroundColor(.white)
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "xkcdy://comics/\(entry.comic.id)"))
    }
}

struct NewSmallComicWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            ComicBadgeHeader(comic: entry.comic)

            Text(verbatim: entry.comic.title).font(.headline).lineLimit(1).padding(.bottom, 1)

            Text(verbatim: entry.comic.alt).font(.caption)
        }.padding()
        .widgetURL(URL(string: "xkcdy://comics/\(entry.comic.id)"))
    }
}

@main
struct NewComicWidget: Widget {
    let kind: String = "NewComicWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ViewLatestComicIntent.self, provider: Provider()) { entry in
            Group {
                if entry.family == .systemSmall {
                    NewSmallComicWidgetEntryView(entry: entry)
                } else {
                    NewComicWidgetEntryView(entry: entry)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .configurationDisplayName("Latest XKCD Comic")
        .description("Displays the latest XKCD comic.")
    }
}

struct NewComicWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewSmallComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemSmall, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemMedium, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemMedium, shouldBlur: true))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            NewComicWidgetEntryView(entry: LastComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemLarge, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
