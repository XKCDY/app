import Foundation
import RealmSwift
import IceCream

class ComicImage: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var u = ""

    var url: URL? {
        get { URL(string: u) }
        set { u = newValue!.absoluteString }
    }

    @objc dynamic var width = 0
    @objc dynamic var height = 0
    @objc dynamic var ratio: Float = 0.0
    @objc dynamic var isDeleted = false
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension ComicImage: CKRecordConvertible, CKRecordRecoverable {}

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
    @objc dynamic var isDeleted = false

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

    func getBestImageURL() -> URL? {
        if let images = imgs {
            if let x2 = images.x2 {
                return x2.url
            }

            if let x1 = images.x1 {
                return x1.url
            }
        }

        return nil
    }

    static func getSample() -> Comic {
        let comic = self.init()

        comic.id = 100
        comic.publishedAt = Date()
        comic.safeTitle = "Sample Comic"
        comic.title = "Sample Comic"
        comic.transcript = "A very short transcript."
        comic.alt = "Some alt text."
        comic.eURL = "https://www.explainxkcd.com/wiki/index.php/2328:_Space_Basketball"
        comic.iURL = "https://victorz.ca/xkcd_map/#10/1.1000/0.2000"

        return comic
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Comic: CKRecordConvertible, CKRecordRecoverable {}

final class Comics: Object {
    @objc dynamic var id = 0
    @objc dynamic var isDeleted = false

    let comics = List<Comic>()

    override class func primaryKey() -> String? {
        "id"
    }
}

extension Comics: CKRecordConvertible, CKRecordRecoverable {}
