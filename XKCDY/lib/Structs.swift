import Foundation
import RealmSwift

class ComicImageObject: Object {
    @objc dynamic var u = ""
    
    var url: URL? {
        get { URL(string: u) }
        set { u = newValue!.absoluteString }
    }
    
    @objc dynamic var width = 0
    @objc dynamic var height = 0
    @objc dynamic var ratio: Float = 0.0
}

class ComicImagesObject: Object {
    @objc dynamic var x1: ComicImageObject?
    @objc dynamic var x2: ComicImageObject?
}

class ComicObject: Object, Identifiable {
    @objc dynamic var id = 0
    @objc dynamic var publishedAt = Date()
    @objc dynamic var news = ""
    @objc dynamic var safeTitle = ""
    @objc dynamic var title = ""
    @objc dynamic var transcript = ""
    @objc dynamic var alt = ""
    @objc dynamic var sURL = ""
    @objc dynamic var eURL = ""
    @objc dynamic var imgs: ComicImagesObject?
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
    
    func getBestImageURL() -> URL? {
    //    return URL(string: "https://imgs.xkcd.com/comics/low_background_metal.png")
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
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Comics: Object {
    @objc dynamic var id = 0
    
    let comics = List<ComicObject>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

struct ComicUrls: Codable {
    let source: URL
    let explain: URL
}

struct ComicImage: Codable {
    let url: URL
    let width: Int
    let height: Int
    let ratio: Float
}

struct ComicImages: Codable {
    let x1: ComicImage
    let x2: ComicImage?
}

struct Comic: Codable, Identifiable {
    let id: Int
    let publishedAt: Date
    let news: String
    let safeTitle: String
    let title: String
    let transcript: String
    let alt: String
    let urls: ComicUrls
    let imgs: ComicImages
    
    func toObject() -> ComicObject {
        let obj = ComicObject()
        
        obj.id = id
        obj.publishedAt = publishedAt
        obj.news = news
        obj.title = title
        obj.transcript = transcript
        obj.alt = alt
        obj.sourceURL = urls.source
        obj.explainURL = urls.explain
        
        let images = ComicImagesObject()
        let x1 = ComicImageObject()
        x1.height = imgs.x1.height
        x1.width = imgs.x1.width
        x1.ratio = imgs.x1.ratio
        x1.url = imgs.x1.url
        
        images.x1 = x1
        
        if let img = imgs.x2 {
            let x2 = ComicImageObject()
            x2.height = img.height
            x2.width = img.width
            x2.ratio = img.ratio
            x2.url = img.url
            
            images.x2 = x2
        }
        
        obj.imgs = images
        
        return obj
    }
}

extension Comic: Equatable {
    static func == (c1: Comic, c2: Comic) -> Bool {
        return c1.id == c2.id
    }
}

extension Comic: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
