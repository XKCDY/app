//
//  Namespaces.swift
//  XKCDY
//
//  Created by Max Isom on 11/17/22.
//  Copyright © 2022 Max Isom. All rights reserved.
//

import SwiftUI

class Namespaces: ObservableObject {
    let gallery: Namespace.ID

    init(gallery: Namespace.ID) {
        self.gallery = gallery
    }
}
