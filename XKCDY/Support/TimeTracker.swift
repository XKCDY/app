//
//  TimeTracker.swift
//  XKCDY
//
//  Created by Max Isom on 8/5/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import Foundation

final class TimeTracker {
    private var userSettings = UserSettings()
    private var startedAt = Date().currentTimeMillis()

    func startTracker() {
        startedAt = Date().currentTimeMillis()
    }

    func stopTracker() {
        let difference = Date().currentTimeMillis() - startedAt

        userSettings.timeSpentInApp += difference
    }
}
