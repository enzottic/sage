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
        log.info("viewDidAppear — starting handleIncomingImage")
        Task { await handleIncomingImage() }
    }

    @MainActor
    private func handleIncomingImage() async {
        log.info("handleIncomingImage called")
        log.info("extensionContext: \(self.extensionContext != nil ? "present" : "nil")")
        log.info("inputItems count: \(self.extensionContext?.inputItems.count ?? -1)")

        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            })
        else {
            log.error("No image attachment found — finishing early")
            return finish()
        }

        log.info("Image provider found, loading item...")

        do {
            let loaded = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            log.info("Loaded item type: \(String(describing: type(of: loaded)))")

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

            log.info("Image loaded: \(image.size.width)x\(image.size.height)")

            do {
                try saveImageToAppGroup(image)
                log.info("Image saved to app group successfully")
            } catch {
                log.error("saveImageToAppGroup failed: \(error)")
                return finish()
            }

            openMainApp()
        } catch {
            log.error("loadItem failed: \(error)")
            finish()
        }
    }

    private func saveImageToAppGroup(_ image: UIImage) throws {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.me.enzottic.SageAppGroup"
        )
        log.info("App group container URL: \(containerURL?.path ?? "NIL — app group not configured")")

        guard let containerURL, let data = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badURL)
        }

        let fileURL = containerURL.appendingPathComponent("pendingReceiptImage.jpg")
        try data.write(to: fileURL)
        log.info("Wrote \(data.count) bytes to \(fileURL.path)")
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
        log.info("Attempting to open \(url.absoluteString) via extensionContext")

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
        log.info("finish() called — completing extension request")
        extensionContext?.completeRequest(returningItems: nil)
    }
}
