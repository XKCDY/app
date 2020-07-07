//
//  ComicBadge.swift
//  XKCDY
//
//  Created by Max Isom on 7/7/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct ComicBadge: View {
    var comic: Comic

    var body: some View {
        HStack {
            if comic.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Text(String(comic.id))
                .font(.caption)
                .fontWeight(.bold)
                .colorScheme(.dark)
        }
        .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
        .background(comic.isRead ? Color(.gray) : Color(.darkGray))
        .cornerRadius(10)
    }
}

struct ComicBadge_Previews: PreviewProvider {
    static var previews: some View {
        ComicBadge(comic: Comic())
    }
}
