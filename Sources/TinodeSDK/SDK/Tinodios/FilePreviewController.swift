//
//  FilePreviewController.swift
//  Tinodios
//
//  Copyright © 2019-2022 Tinode LLC. All rights reserved.
//

import UIKit
import TinodeSDK

struct FilePreviewContent {
    let data: Data
    let refUrl: URL?
    let fileName: String?
    let contentType: String?
    let size: Int?

    // ReplyTo preview (the user is replying to another message with a file).
    let pendingMessagePreview: NSAttributedString?
}

class FilePreviewController: UIViewController, UIScrollViewDelegate {

    var previewContent: FilePreviewContent?
    var replyPreviewDelegate: PendingMessagePreviewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentTypeLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!

    @IBOutlet weak var previewView: RichTextView!
    @IBOutlet weak var previewViewHeight: NSLayoutConstraint!

    @IBAction func sendFileAttachment(_ sender: UIButton) {
        // This notification is received by the MessageViewController.
        NotificationCenter.default.post(name: Notification.Name(MessageViewController.kNotificationSendAttachment), object: previewContent)
        // Return to MessageViewController.
        navigationController?.popViewController(animated: true)
    }

    @IBAction func cancelPreviewClicked(_ sender: Any) {
        self.togglePreviewBar(with: nil)
        self.replyPreviewDelegate?.dismissPendingMessagePreview()
    }

    private func setup() {
        guard let content = self.previewContent else { return }

        // Set icon appropriate for mime type
        imageView.image = UIImage(named: FilePreviewController.iconFromMime(previewContent?.contentType))

        // Fill out attachment details.
        fileNameLabel.text = content.fileName ?? NSLocalizedString("undefined", comment: "Placeholder for missing file name")
        contentTypeLabel.text = content.contentType ?? NSLocalizedString("undefined", comment: "Placeholder for missing file type")
        var sizeString = "?? KB"
        if let size = content.size {
            sizeString = UiUtils.bytesToHumanSize(Int64(size))
        }
        sizeLabel.text = sizeString
        self.togglePreviewBar(with: content.pendingMessagePreview)

        setInterfaceColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        self.setInterfaceColors()
    }

    private func setInterfaceColors() {
        if traitCollection.userInterfaceStyle == .dark {
            self.view.backgroundColor = .black
        } else {
            self.view.backgroundColor = .white
        }
    }

    // Get icon name from mime type.
    // If more icons become available in material icons, add them to this mime-to-icon mapping.
    static let kMimeToIcon = ["text": "file-text-125", "image": "file-image-125", "video": "file-video-125", "audio": "file-audio-125"]
    static let kDefaultIcon = "file"
    private static func iconFromMime(_ mime: String?) -> String {
        guard let mime = mime else { return FilePreviewController.kDefaultIcon }

        // Try full mime type first, e.g. "text/plain".
        if let icon = FilePreviewController.kMimeToIcon[mime] {
            return icon
        }

        // Full not found, try major part, e.g. "text/plain" -> "text".
        let parts = mime.split(separator: "/")
        if let icon = FilePreviewController.kMimeToIcon[String(parts[0])] {
            return icon
        }

        return FilePreviewController.kDefaultIcon
    }

    public func togglePreviewBar(with message: NSAttributedString?) {
        if let message = message, let delegate = self.replyPreviewDelegate {
            let textBounds = delegate.pendingPreviewMessageSize(forMessage: message)
            previewViewHeight.constant = textBounds.height
            previewView.attributedText = message
            previewView.isHidden = false
        } else {
            previewViewHeight.constant = CGFloat.zero
            previewView.attributedText = nil
            previewView.isHidden = true
        }
    }
}
