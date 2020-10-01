//
//  XKCDYWidgetBundle.swift
//  Widgets
//
//  Created by Max Isom on 9/20/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct XKCDYWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        NewOrRandomComicWidget()
        RandomComicWidget()
        NewComicWidget()
    }
}
