import SwiftUI
import UIKit
import Combine
import CHTCollectionViewWaterfallLayout
import class Kingfisher.ImagePrefetcher

import Foundation

// todo: better pull to refresh animation



final class ComicCollectionCell: UICollectionViewCell {
    private var vm: ComicGridItemViewModel?
    private var cell: ComicGridItem?

    var viewModel: Comic? {
        didSet {
            guard let comic = viewModel else {
                fatalError()
            }

            if self.vm == nil {
                self.vm = ComicGridItemViewModel(comic: comic)
            } else {
                self.vm?.comic = comic
            }

            if self.cell == nil {
                self.cell = ComicGridItem(vm: self.vm!)
                let hostingController = UIHostingController(rootView: self.cell)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(hostingController.view)

                hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor)
                    .isActive = true
                hostingController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor)
                    .isActive = true
                hostingController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor)
                    .isActive = true
                hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                    .isActive = true
            }
        }
    }

    override init(frame _: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




typealias PullToRefreshCompletion = () -> Void

final class ComicWaterfallViewController: UIViewController, CHTCollectionViewDelegateWaterfallLayout, UICollectionViewDataSourcePrefetching {
    init(loadMoreSubject: PassthroughSubject<Void, Never>? = nil,
         itemSelectionSubject: PassthroughSubject<IndexPath, Never>? = nil,
         pullToRefreshSubject: PassthroughSubject<PullToRefreshCompletion, Never>? = nil,
         prefetchLimit: Int) {
        self.prefetchLimit = prefetchLimit
        self.loadMoreSubject = loadMoreSubject
        self.itemSelectionSubject = itemSelectionSubject
        self.pullToRefreshSubject = pullToRefreshSubject
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSnapshot(items: [Comic]) {
        isPaginating = false
        self.items = items
        var snapshot = NSDiffableDataSourceSnapshot<Section, Comic>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comic = items[indexPath.item]
        let img = comic.getBestAvailableSize()
        return CGSize(width: img?.width ?? 0, height: img?.height ?? 0)
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with _: UIViewControllerTransitionCoordinator
    ) {
        collectionView.refreshControl?.tintColor = newCollection
            .userInterfaceStyle == .dark ? .white : .black
    }

    private func setupView() {
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }

    private let prefetchLimit: Int
    private var items = [Comic]()
    private var isPaginating = false

    private let loadMoreSubject: PassthroughSubject<Void, Never>?
    private let itemSelectionSubject: PassthroughSubject<IndexPath, Never>?
    private let pullToRefreshSubject: PassthroughSubject<PullToRefreshCompletion, Never>?

    enum Section {
        case main
    }

    private lazy var layout: UICollectionViewLayout = {
        let layout = CHTCollectionViewWaterfallLayout()

        layout.minimumColumnSpacing = 16.0
        layout.minimumInteritemSpacing = 16.0
        // todo: set dynamically
        layout.columnCount = 3

        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.view.bounds,
                                              collectionViewLayout: self.layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ComicCollectionCell.self,
                                forCellWithReuseIdentifier: "ComicCollectionCell")

        collectionView.delegate = self
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(
            self,
            action: #selector(pullToRefreshAction),
            for: .valueChanged
        )

        collectionView.refreshControl?.tintColor = traitCollection
            .userInterfaceStyle == .dark ? .white : .black

        collectionView.prefetchDataSource = self

        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Comic> = {
        let dataSource: UICollectionViewDiffableDataSource<Section, Comic> =
            UICollectionViewDiffableDataSource(
                collectionView: collectionView
            ) { [weak self] collectionView, indexPath, viewModel in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ComicCollectionCell",
                    for: indexPath
                ) as? ComicCollectionCell
                else { fatalError("Cannot create comic cell") }

                cell.viewModel = viewModel

                return cell
            }

        return dataSource
    }()

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        ImagePrefetcher(urls: indexPaths.compactMap { [weak self] in self?.dataSource.itemIdentifier(for: $0)}.compactMap {$0.getReasonableImageURL()}).start()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        ImagePrefetcher(urls: indexPaths.compactMap { [weak self] in self?.dataSource.itemIdentifier(for: $0)}.compactMap {$0.getReasonableImageURL()}).stop()
    }
}

extension ComicWaterfallViewController {
    @objc private func pullToRefreshAction() {
        pullToRefreshSubject?.send {
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
}

extension ComicWaterfallViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        itemSelectionSubject?.send(indexPath)
    }
}









struct ComicWaterfallView: UIViewControllerRepresentable {
    private var items: [Comic]

    private let loadMoreSubject: PassthroughSubject<Void, Never>?
    private let itemSelectionSubject: PassthroughSubject<IndexPath, Never>?
    private let pullToRefreshSubject: PassthroughSubject<PullToRefreshCompletion, Never>?
    private let prefetchLimit: Int

    // MARK: Init

    init(items: [Comic],
         loadMoreSubject: PassthroughSubject<Void, Never>? = nil,
         itemSelectionSubject: PassthroughSubject<IndexPath, Never>? = nil,
         pullToRefreshSubject: PassthroughSubject<PullToRefreshCompletion, Never>? = nil,
         prefetchLimit: Int = 10) {
        self.items = items
        self.loadMoreSubject = loadMoreSubject
        self.itemSelectionSubject = itemSelectionSubject
        self.pullToRefreshSubject = pullToRefreshSubject
        self.prefetchLimit = prefetchLimit
    }

    func makeUIViewController(context _: Context)
        -> ComicWaterfallViewController {
        ComicWaterfallViewController(
            loadMoreSubject: loadMoreSubject,
            itemSelectionSubject: itemSelectionSubject,
            pullToRefreshSubject: pullToRefreshSubject,
            prefetchLimit: prefetchLimit
        )
    }

    func updateUIViewController(
        _ view: ComicWaterfallViewController,
        context _: Context
    ) {
        view.updateSnapshot(items: items)
    }
}

