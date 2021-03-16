//
//  Views.swift
//  Widgets
//
//  Created by Max Isom on 9/20/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import WidgetKit

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

struct LargeComicWidgetView: View {
    var entry: LatestComicWidgetProvider.Entry

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
                Image(uiImage: entry.uiImage).resizable().aspectRatio(contentMode: .fill).scaleEffect(1.05).blur(radius: entry.shouldBlur ? 5 : 0)

                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5), Color.white.opacity(0)]), startPoint: .top, endPoint: .bottom)).frame(width: geom.size.width, height: geom.size.height / 2)

                HStack {
                    ComicBadgeHeader(comic: entry.comic)

                    Text(entry.comic.safeTitle).font(.headline).lineLimit(1).foregroundColor(.white)
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "xkcdy://comics/\(entry.comic.id)"))
    }
}

struct SmallComicWidgetView: View {
    var entry: LatestComicWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            ComicBadgeHeader(comic: entry.comic)

            Text(verbatim: entry.comic.safeTitle).font(.headline).lineLimit(1).padding(.bottom, 1)

            Text(verbatim: entry.comic.alt).font(.caption)

            Spacer(minLength: 0)
        }
        .padding()
        .widgetURL(URL(string: "xkcdy://comics/\(entry.comic.id)"))
    }
}

struct ComicWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmallComicWidgetView(entry: ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemSmall, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            LargeComicWidgetView(entry: ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemMedium, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            LargeComicWidgetView(entry: ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemMedium, shouldBlur: true))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            LargeComicWidgetView(entry: ComicEntry(date: Date(), comic: .getTallSample(), uiImage: UIImage(named: "2329_2x.png")!, family: .systemLarge, shouldBlur: false))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
