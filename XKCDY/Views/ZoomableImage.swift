import UIKit
import SwiftUI
import Kingfisher

class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    let tapMaxDelay: Double = 0.3 //anything below 0.3 may cause doubleTap to be inaccessible by many users

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
            if self?.state != UIGestureRecognizer.State.recognized {
                self?.state = UIGestureRecognizer.State.failed
            }
        }
    }
}

class ZoomableImage: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var imageView: UIImageView!
    var singleTapRecognizer: UITapGestureRecognizer!
    var doubleTapRecognizer: UITapGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!
    var onSingleTap: () -> Void = {}
    var onLongPress: () -> Void = {}
    var onScale: (CGFloat) -> Void = {_ in}
    var orientation = UIDevice.current.orientation

    convenience init(frame f: CGRect, image: UIImageView, onSingleTap: @escaping () -> Void, onLongPress: @escaping () -> Void, onScale: @escaping (CGFloat) -> Void) {
        self.init(frame: f)

        self.onSingleTap = onSingleTap
        self.onLongPress = onLongPress
        self.onScale = onScale

        imageView = image

        imageView.frame = f
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        setupScrollView()
        setupGestureRecognizer()

        updateInset()
    }

    func updateInset() {
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            contentInset = UIEdgeInsets(top: window.safeAreaInsets.top, left: window.safeAreaInsets.left, bottom: window.safeAreaInsets.bottom, right: window.safeAreaInsets.right)
        }
    }

    private func setupScrollView() {
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
    }

    private func setupGestureRecognizer() {
        doubleTapRecognizer = UIShortTapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapRecognizer)

        singleTapRecognizer = UIShortTapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapRecognizer)

        singleTapRecognizer.require(toFail: doubleTapRecognizer)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressRecognizer)
    }

    @objc private func handleSingleTap() {
        onSingleTap()
    }

    @objc private func handleDoubleTap() {
        if zoomScale == 1 {
            zoom(to: zoomRectForScale(maximumZoomScale, center: doubleTapRecognizer.location(in: doubleTapRecognizer.view)), animated: true)
        } else {
            setZoomScale(minimumZoomScale, animated: true)
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.onScale(scale)
        if scale == 1 {
            isScrollEnabled = false
        } else {
            isScrollEnabled = true
        }
    }

    @objc private func handleLongPress() {
        onLongPress()
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    internal func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

struct ZoomableImageView: UIViewRepresentable {
    var imageURL: URL
    var onSingleTap: () -> Void
    var onLongPress: () -> Void
    var onScale: (CGFloat) -> Void
    var frame: CGRect = .infinite

    func makeUIView(context: Context) -> ZoomableImage {
        let image = UIImageView()
        image.kf.setImage(with: imageURL)

        return ZoomableImage(frame: frame, image: image, onSingleTap: onSingleTap, onLongPress: onLongPress, onScale: onScale)
    }

    func updateUIView(_ uiView: ZoomableImage, context: Context) {
        // Only should update on orientation change
        if uiView.orientation != UIDevice.current.orientation {
            uiView.updateInset()
            uiView.frame = frame
            uiView.setZoomScale(1, animated: false)
            uiView.isScrollEnabled = false
            uiView.imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            uiView.contentSize = frame.size

            uiView.orientation = UIDevice.current.orientation

            DispatchQueue.main.async {
                self.onScale(1)
            }
        }
    }
}

extension ZoomableImageView {
    func frame(from f: CGRect) -> Self {
        var copy = self
        copy.frame = f

        return copy
    }
}
