import Foundation
import Alamofire

struct ComicImgResponse: Decodable {
    let height: Int
    let width: Int
    let ratio: Float
    let sourceUrl: String
    let size: String
}

struct ComicResponse: Decodable {
    let id: Int
    let publishedAt: Date
    let news: String
    let safeTitle: String
    let title: String
    let transcript: String
    let alt: String
    let sourceUrl: String
    let explainUrl: String
    let interactiveUrl: String?
    let imgs: [ComicImgResponse]
}

enum APIError: Error {
    case other
    case decoding
}


let BASE_URL = "https://api.xkcdy.com"

final class API {
    static func getComics(completion: @escaping (Result<[ComicResponse], APIError>) -> Void) {
        self.getComics(since: 0, completion: completion)
    }
    
    static func getComics(since: Int, completion: @escaping (Result<[ComicResponse], APIError>) -> Void) {
        AF.request("\(BASE_URL)/comics", parameters: ["since": String(since)]).responseDecodable(of: [ComicResponse].self, decoder: self.getDecoder()) { (response: AFDataResponse<[ComicResponse]>) -> () in
            do {
                completion(.success(try response.result.get()))
            } catch {
                completion(.failure(.decoding))
            }
        }
    }
    
    private static func getDecoder() -> JSONDecoder {
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
