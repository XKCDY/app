//
//  XKCDTimeClient.swift
//  XKCDY
//
//  Created by Max Isom on 9/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import Alamofire

struct TimeComicFrameResponse: Decodable {
    let apocryphal: Bool
    let baFrameNo: String
    let downloadedUrl: String
    let epoch: Int
    let frameNo: String
    let gwFrameNo: String
    let hash: String
    let xkcdUrl: String
}

extension TimeComicFrameResponse {
    func getImageURL() -> URL? {
        return URL(string: xkcdUrl)
    }
}

extension TimeComicFrameResponse {
    func toObject() -> TimeComicFrame {
        let frame = TimeComicFrame()

        frame.id = hash
        frame.date = Date(timeIntervalSince1970: Double(epoch) / 1000.0)
        frame.url = xkcdUrl
        frame.frameNumber = Int(frameNo) ?? 0

        return frame
    }
}

final class XKCDTimeClient {
    static func getFrames(completion: @escaping (Result<[TimeComicFrameResponse], APIError>) -> Void) {
        AF.request("https://xkcd.mscha.org/time.json").responseDecodable(of: [TimeComicFrameResponse].self) { (response: AFDataResponse<[TimeComicFrameResponse]>) -> Void in
            do {
                completion(.success(try response.result.get()))
            } catch {
                completion(.failure(.decoding))
            }

        }
    }
}
