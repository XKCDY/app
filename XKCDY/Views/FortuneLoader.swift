//
//  FortuneLoader.swift
//  XKCDY
//
//  Created by Max Isom on 8/6/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct FortuneLoader: View {
    @State private var fortune = Fortunes().getRandom()
    @State private var timer: Timer?

    var body: some View {
        VStack {
            ActivityIndicator(style: .large)

            Text(fortune.text)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .id("FortuneLoader" + fortune.text)
                .padding()

            Text(String(fortune.comicId))
                .id("FortuneLoader" + String(fortune.comicId))
                .font(Font.caption.bold())
        }
        .transition(.opacity)
        .animation(.default)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
                self.timer = timer
                self.fortune = Fortunes().getRandom()
            }
        }
        .onDisappear {
            self.timer?.invalidate()
        }
    }
}

struct FortuneLoader_Previews: PreviewProvider {
    static var previews: some View {
        FortuneLoader()
    }
}
