//
//  SharableComicView.swift
//  XKCDY
//
//  Created by Max Isom on 8/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import KingfisherSwiftUI

struct SharableComicView: View {
    var comic: Comic
    @State private var isLoaded = false

    func getFontSize() -> CGFloat {
        if comic.imgs?.x2 != nil {
            return 30
        }

        return 20
    }

    var body: some View {
        VStack {
            HStack {
                Text("#\(comic.id):").font(Font.system(size: self.getFontSize()).bold())

                Text(comic.title).lineLimit(1)

                Spacer()

                Text(getDateFormatter().string(from: comic.publishedAt))
            }
            .padding()

            KFImage(comic.getBestImageURL(), isLoaded: self.$isLoaded)

            HStack {
                Text(comic.alt)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding()
        }.font(Font.system(size: self.getFontSize()))
    }

    func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()

        formatter.dateFormat = "MMMM d, yyyy"

        return formatter
    }
}

// https://stackoverflow.com/a/59333377/2129808, https://ericasadun.com/2019/06/20/swiftui-render-your-mojave-swiftui-views-on-the-fly/
extension View {
    func asImage(completionHandler: @escaping (UIImage) -> Void) {
        let controller = UIHostingController(rootView: self)

        // locate far out of screen
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)

        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        controller.view.backgroundColor = .black

        DispatchQueue.main.async {
            let image = controller.view.renderedImage
            controller.view.removeFromSuperview()

            completionHandler(image)
        }
    }
}

extension UIView {
    var renderedImage: UIImage {
        let image = UIGraphicsImageRenderer(size: self.bounds.size).image { context in
            UIRectFill(bounds)

            self.layer.render(in: context.cgContext)
        }

        return image
    }
}

struct SharableComicView_Previews: PreviewProvider {
    static var comic = Comic.getSample()

    static var previews: some View {
        SharableComicView(comic: comic)
    }
}
