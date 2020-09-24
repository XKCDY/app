import Foundation
import RealmSwift
import UIKit

class ComicImage: Object {
    @objc dynamic var u = ""

    var url: URL? {
        get { URL(string: u) }
        set { u = newValue!.absoluteString }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
    }

    @objc dynamic var width = 0
    @objc dynamic var height = 0
    @objc dynamic var ratio: Float = 0.0
}

class ComicImages: Object {
    @objc dynamic var x1: ComicImage?
    @objc dynamic var x2: ComicImage?
}

class Comic: Object, Identifiable {
    @objc dynamic var id = 0
    @objc dynamic var publishedAt = Date()
    @objc dynamic var news = ""
    @objc dynamic var safeTitle = ""
    @objc dynamic var title = ""
    @objc dynamic var transcript = ""
    @objc dynamic var alt = ""
    @objc dynamic var sURL = ""
    @objc dynamic var eURL = ""
    @objc dynamic var iURL: String?
    @objc dynamic var imgs: ComicImages?
    @objc dynamic var isFavorite = false
    @objc dynamic var isRead = false

    var sourceURL: URL? {
        get { URL(string: sURL) }

        set { sURL = newValue!.absoluteString }
    }

    var explainURL: URL? {
        get { URL(string: eURL) }

        set { eURL = newValue!.absoluteString }
    }

    var interactiveUrl: URL? {
        get { iURL == nil ? nil : URL(string: iURL!) }

        set { iURL = newValue != nil ? newValue!.absoluteString : nil }
    }

    static func getSample() -> Comic {
        let comic = self.init()

        comic.id = 100
        comic.publishedAt = Date()
        comic.safeTitle = "Sample Comic"
        comic.title = "Sample Comic with long long long title"
        comic.transcript = "A very short transcript."
        comic.alt = "Some alt text."
        comic.eURL = "https://www.explainxkcd.com/wiki/index.php/2328:_Space_Basketball"
        comic.iURL = "https://victorz.ca/xkcd_map/#10/1.1000/0.2000"

        let image = ComicImage()
        image.height = 510
        image.width = 1480
        image.ratio = 2.90196078431373
        image.url = URL(string: "https://imgs.xkcd.com/comics/acceptable_risk_2x.png")

        let images = ComicImages()
        images.x2 = image

        comic.imgs = images

        return comic
    }

    static func getTallSample() -> Comic {
        let comic = self.init()

        comic.id = 2329
        comic.publishedAt = Date()
        comic.safeTitle = "Universal Rating Scale"
        comic.title = "Universal Rating Scale"
        comic.transcript = "No transcript"
        comic.alt = "There are plenty of finer gradations. I got 'critically endangered/extinct in the wild' on my exam, although the curve bumped it all the way up to 'venti.'"
        comic.eURL = "https://www.explainxkcd.com/wiki/index.php/2329:_Universal_Rating_Scale"

        let image = ComicImage()
        image.height = 1945
        image.width = 443
        image.ratio = 0.227763496143959
        image.url = URL(string: "https://imgs.xkcd.com/comics/universal_rating_scale_2x.png")

        let images = ComicImages()
        images.x2 = image

        comic.imgs = images

        return comic
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Comic {
    // Return x1 if x2 is absurdly large
    func getReasonableImageURL() -> URL? {
        if let images = imgs {
            if let x2 = images.x2 {
                if x2.width * x2.height < 50000000 {
                    return x2.url
                }
            }
        }

        return imgs?.x1?.url
    }

    // Always return x2 if it exists
    func getBestImageURL() -> URL? {
        return imgs?.x2?.url ?? imgs?.x1?.url
    }
}

final class Comics: Object {
    @objc dynamic var id = 0

    let comics = List<Comic>()

    override class func primaryKey() -> String? {
        "id"
    }
}

final class LastFilteredComics: Object {
    @objc dynamic var id = 0

    let comics = List<Comic>()

    override class func primaryKey() -> String? {
        "id"
    }
}
