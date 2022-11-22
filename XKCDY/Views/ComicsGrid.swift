//
//  ContentView.swift
//  DCKX
//
//  Created by Max Isom on 4/13/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import UIKit
import Combine
import RealmSwift

enum ScrollDirection {
    case up, down
}

@propertyWrapper struct PublishedWithoutViewUpdate<Value> {
    let publisher: PassthroughSubject<Void, Never>
    private var _wrappedValue: Value

    init(wrappedValue: Value) {
        self.publisher = PassthroughSubject()
        self._wrappedValue = wrappedValue
    }

    var wrappedValue: Value {
        get {
            _wrappedValue
        }

        set {
            _wrappedValue = newValue
            publisher.send()
        }
    }

    var projectedValue: PassthroughSubject<Void, Never> {
        self.publisher
    }
}

class ScrollStateModel: ObservableObject {
    @Published var isScrolling = false
    @PublishedWithoutViewUpdate var scrollPosition: CGFloat = 0 {
        willSet {
            if !self.isScrolling {
                self.isScrolling = true
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        $scrollPosition
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.global())
            .sink { _ in
                DispatchQueue.main.async {
                    self.isScrolling = false
                }
            }
            .store(in: &cancellables)
    }
}



struct ComicsGridView: View {
    @State var columnMinSize: CGFloat = 150
    @State var inViewUrls: [String] = []
    @Binding var scrollDirection: ScrollDirection
    @EnvironmentObject var store: Store
    @State private var showErrorAlert = false
    @State private var lastScrollPositions: [CGFloat] = []
    @State private var shouldBlurStatusBar = false
    @ObservedObject private var scrollState = ScrollStateModel()

    @EnvironmentObject var galleryVm: ComicGalleryViewModel

    func onPullToRefresh(_ endRefreshing: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.store.refetchComics { result -> Void in
                endRefreshing()

                switch result {
                case .success:
                    self.showErrorAlert = false
                case .failure:
                    self.showErrorAlert = true
                }
            }
        }
    }

    var body: some View {
        VStack {
            ComicWaterfallView(items: self.store.filteredComics.sorted(byKeyPath: "id", ascending: false).enumerated().map { $1 })
        }
    }
}
