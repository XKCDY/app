//
//  SharableComicView.swift
//  XKCDY
//
//  Created by Max Isom on 8/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import Kingfisher

struct SharableComicView: View {
    var comic: Comic
    @State private var isLoaded = false

    func getFontSize() -> CGFloat {
        if let ratio = comic.imgs?.x1?.ratio {
            if ratio > 1 {
                return 30
            }
        }

        return 20
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text("#\(comic.id):")
                    .font(Font.system(size: self.getFontSize()).bold())
                    .foregroundColor(Color.white)

                Text(comic.safeTitle)
                    .lineLimit(1)
                    .foregroundColor(Color.white)

                Spacer()

                Text(getDateFormatter().string(from: comic.publishedAt))
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal)
            .padding(.vertical, self.getFontSize() / 2)

            KFImage(comic.getBestImageURL())
                .onSuccess({ _ in
                    self.isLoaded = true
                })
                .resizable()
                .frame(height: CGFloat(comic.getBestAvailableSize()?.height ?? 0))

            HStack {
                Text(comic.alt)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, self.getFontSize() / 2)
        }
        .padding(.vertical)
        .font(Font.system(size: self.getFontSize()))
        .frame(width: CGFloat(comic.getBestAvailableSize()?.width ?? 0))
        .ignoresSafeArea()
        .background(Color.black)
    }

    func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()

        formatter.dateFormat = "MMMM d, yyyy"

        return formatter
    }
}

// https://stackoverflow.com/a/59333377/2129808, https://ericasadun.com/2019/06/20/swiftui-render-your-mojave-swiftui-views-on-the-fly/
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .black

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct SharableComicView_Previews: PreviewProvider {
    static var comic = Comic.getSample()

    static var previews: some View {
        SharableComicView(comic: comic)
    }
}
