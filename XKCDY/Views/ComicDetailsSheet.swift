//
//  ComicDetailsSheet.swift
//  XKCDY
//
//  Created by Max Isom on 7/8/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI

struct ComicDetailsSheet: View {
    var comic: Comic
    var onDismiss: () -> Void
    @State private var showSheet = false
    @State private var sheetUrl: URL?

    func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()

        formatter.dateFormat = "MMMM d, yyyy"

        return formatter
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("#\(comic.id)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(getDateFormatter().string(from: comic.publishedAt))
                            .font(.headline)
                    }

                    Spacer()
                }.padding()

                Spacer()

                Text(comic.alt)
                    .padding()

                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        if let explainURL = self.comic.explainURL {
                            self.sheetUrl = explainURL
                            self.showSheet = true
                        }
                    }) {
                        Image(systemName: "questionmark.circle.fill").resizable().scaledToFit().frame(width: 24, height: 24)
                    }

                    if self.comic.interactiveUrl != nil {
                        Button(action: {
                            if let interactiveURL = self.comic.interactiveUrl {
                                self.sheetUrl = interactiveURL
                                self.showSheet = true
                            }
                        }) {
                            Image(systemName: "wand.and.stars").resizable().scaledToFit().frame(width: 24, height: 24)
                        }
                        .padding(.leading)
                    }
                }
                .padding(30)
            }
            .navigationBarTitle(Text(comic.title), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: self.onDismiss) {
                Text("Done").bold()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showSheet) {
                UncontrolledWebView(url: self.sheetUrl ?? URL(string: "https://xkcdy.com")!, onDismiss: {
                    self.showSheet = false
            })
        }
    }
}

struct ComicDetailsSheet_Previews: PreviewProvider {
    static var previews: some View {
        ComicDetailsSheet(comic: .getSample(), onDismiss: {})
    }
}
