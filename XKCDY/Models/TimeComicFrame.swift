//
//  TimeComicFrame.swift
//  XKCDY
//
//  Created by Max Isom on 9/16/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation
import RealmSwift

class TimeComicFrame: Object {
    @objc dynamic var id = ""
    @objc dynamic var date = Date()
    @objc dynamic var url = ""
    @objc dynamic var frameNumber = 0

    func getURL() -> URL? {
        URL(string: url)
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func indexedProperties() -> [String] {
        return ["id", "frameNumber"]
    }
}
