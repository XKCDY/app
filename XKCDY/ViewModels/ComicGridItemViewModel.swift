//
//  ComicGridItemViewModel.swift
//  XKCDY
//
//  Created by Max Isom on 11/16/22.
//  Copyright © 2022 Max Isom. All rights reserved.
//

import Foundation

class ComicGridItemViewModel: ObservableObject {
    @Published var comic: Comic

    init(comic: Comic) {
        self.comic = comic
    }
}
