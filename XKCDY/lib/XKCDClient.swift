import Foundation
import Alamofire

struct APIResponse: Decodable {
    let month: String
    let num: Int
    let link: String
    let year: String
    let news: String
    let safe_title: String
    let transcript: String
    let alt: String
    let img: String
    let title: String
    let day: String
}

let BASE_URL = "https://xkcdy.now.sh/api/comics"

struct xkcd {
    static func getAllComics(completion: @escaping ([Comic]?) -> Void) {
        self.getComicsSince(since: 0) { res in
            completion(res)
        }
    }

    static func getComicsSince(since: Int, completion: @escaping ([Comic]?) -> Void) {
        AF.request(BASE_URL, parameters: ["since": String(since)]).responseDecodable(of: [Comic].self, decoder: self.getDecoder()) { (response: AFDataResponse<[Comic]>) in
            do {
                completion(try response.result.get())
            } catch {
                completion(nil)
            }
        }
    }

     static func getDecoder() -> JSONDecoder {
        enum DateError: String, Error {
            case invalidDate
        }

        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DateError.invalidDate
        })

        return decoder
    }
}
