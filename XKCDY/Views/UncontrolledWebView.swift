//
//  UncontrolledWebView.swift
//  XKCDY
//
//  Created by Max Isom on 7/8/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import WebView

struct ControlledWebView: View {
    var onDismiss: () -> Void
    var webViewStore: WebViewStore

    var body: some View {
        NavigationView {
          WebView(webView: webViewStore.webView)
            .navigationBarTitle(Text(verbatim: webViewStore.webView.title ?? ""), displayMode: .inline)
            .navigationBarItems(leading: HStack {
                Button(action: goBack) {
                  Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                }.disabled(!webViewStore.webView.canGoBack)

                Button(action: goForward) {
                  Image(systemName: "chevron.right")
                    .imageScale(.large)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                }.disabled(!webViewStore.webView.canGoForward)
            }, trailing: HStack {
                Button(action: onDismiss) {
                    Text("Done")
                }
            })
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationViewStyle(StackNavigationViewStyle())
//        .onAppear {
//            self.webViewStore.webView.load(URLRequest(url: self.url))
//        }
    }

    func goBack() {
      webViewStore.webView.goBack()
    }

    func goForward() {
      webViewStore.webView.goForward()
    }
}

struct UncontrolledWebView_Previews: PreviewProvider {
    static var previews: some View {
        ControlledWebView(url: URL(string: "https://apple.com")!, onDismiss: {}, webViewStore: WebViewStore())
    }
}
