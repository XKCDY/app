import UIKit
import SwiftUI
import LinkPresentation

class ImageInfoSource: UIViewController, UIActivityItemSource {
    var uiImage: UIImage!
    var text: String!
    var url: URL!

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let imageProvider = NSItemProvider(object: uiImage)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = text
        metadata.originalURL = url

        return metadata
    }
}

struct SwiftUIActivityViewController: UIViewControllerRepresentable {
    let uiImage: UIImage
    let title: String
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let source = ImageInfoSource()

        source.uiImage = uiImage
        source.text = title
        source.url = url

        let activityViewController = UIActivityViewController(activityItems: [uiImage, source], applicationActivities: [])

        return activityViewController
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
