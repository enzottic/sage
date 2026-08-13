//
//  ShareViewController.swift
//  FinanceTrackerShareExtension
//
//  Created by Tyler McCormick on 5/23/26.
//
import UIKit
import UniformTypeIdentifiers
import OSLog

private let log = Logger(subsystem: "me.enzottic.FinanceTracker.ShareExtension", category: "ShareViewController")

@objc private protocol URLOpener {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler: ((Bool) -> Void)?)
}

class ShareViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await handleIncomingImage() }
    }

    @MainActor
    private func handleIncomingImage() async {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            })
        else {
            log.error("No image attachment found — finishing early")
            return finish()
        }

        do {
            let loaded = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)

            let image: UIImage? = switch loaded {
                case let img as UIImage: img
                case let url as URL:     UIImage(contentsOfFile: url.path)
                case let data as Data:   UIImage(data: data)
                default: nil
            }

            guard let image else {
                log.error("Could not convert loaded item to UIImage")
                return finish()
            }

            do {
                try saveImageToAppGroup(image)
            } catch {
                log.error("Could not save shared receipt image: \(error.localizedDescription, privacy: .private(mask: .hash))")
                return finish()
            }

            openMainApp()
        } catch {
            log.error("Could not load shared receipt image: \(error.localizedDescription, privacy: .private(mask: .hash))")
            finish()
        }
    }

    private func saveImageToAppGroup(_ image: UIImage) throws {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.me.enzottic.SageAppGroup"
        )
        guard let containerURL, let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badURL)
        }

        let fileURL = containerURL.appendingPathComponent("pendingReceiptImage.jpg")
        try data.write(to: fileURL)
    }

    @MainActor
    private func openMainApp() {
        #if DEBUG
        let urlString = "sage-dev://add-expense?source=receipt"
        #else
        let urlString = "sage://add-expense?source=receipt"
        #endif
        guard let url = URL(string: urlString) else {
            log.error("Could not create the Sage deep link")
            finish()
            return
        }
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }
        finish()
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
