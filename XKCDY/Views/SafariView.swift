//
//  SafariView.swift
//  XKCDY
//
//  Created by Max Isom on 9/12/20.
//  Copyright © 2020 Max Isom. All rights reserved.
//

import SwiftUI
import UIKit
import SafariServices

// https://david.y4ng.fr/swiftui-and-sfsafariviewcontroller/
struct SafariView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CustomSafariViewController

    var url: URL?

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> CustomSafariViewController {
        return CustomSafariViewController()
    }

    func updateUIViewController(_ safariViewController: CustomSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
        safariViewController.url = url
    }
}

final class CustomSafariViewController: UIViewController {
    var url: URL? {
        didSet {
            // when url changes, reset the safari child view controller
            configureChildViewController()
        }
    }

    private var safariViewController: SFSafariViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureChildViewController()
    }

    private func configureChildViewController() {
        // Remove the previous safari child view controller if not nil
        if let safariViewController = safariViewController {
            safariViewController.willMove(toParent: self)
            safariViewController.view.removeFromSuperview()
            safariViewController.removeFromParent()
            self.safariViewController = nil
        }

        guard let url = url else { return }

        // Create a new safari child view controller with the url
        let newSafariViewController = SFSafariViewController(url: url)
        addChild(newSafariViewController)
        newSafariViewController.view.frame = view.frame
        view.addSubview(newSafariViewController.view)
        newSafariViewController.didMove(toParent: self)
        self.safariViewController = newSafariViewController
    }
}
