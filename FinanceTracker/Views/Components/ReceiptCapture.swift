//
//  ReceiptCapture.swift
//  FinanceTracker
//
//  Hosts the "import from receipt" capture flow used by the add menu: it presents
//  the camera or photo library, stashes the chosen image via ReceiptHandoffService,
//  then presents AddExpenseView, which consumes and parses the pending image.
//

import SwiftUI
import PhotosUI
import SageKit

/// Which source the receipt image should come from. Driven by the add menu.
enum ReceiptCaptureSource: Identifiable {
    case camera
    case library

    var id: Self { self }
}

extension View {
    /// Attaches the receipt capture flow. Set `source` (from the add menu) to begin;
    /// the modifier presents the picker, stashes the image, and opens AddExpenseView.
    func receiptCapture(source: Binding<ReceiptCaptureSource?>) -> some View {
        modifier(ReceiptCaptureModifier(source: source))
    }
}

private struct ReceiptCaptureModifier: ViewModifier {
    @Environment(AppRouter.self) private var appRouter
    @Binding var source: ReceiptCaptureSource?
    @State private var photoItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: cameraBinding) {
                CameraPickerView { image in handle(image) }
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: libraryBinding, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    await MainActor.run {
                        photoItem = nil
                        if let data, let image = UIImage(data: data) {
                            handle(image)
                        }
                    }
                }
            }
    }

    private var cameraBinding: Binding<Bool> {
        Binding(get: { source == .camera }, set: { if !$0 { source = nil } })
    }

    private var libraryBinding: Binding<Bool> {
        Binding(get: { source == .library }, set: { if !$0 { source = nil } })
    }

    /// Stashes the image for handoff and presents AddExpenseView. The short delay lets
    /// the capture sheet finish dismissing before the add sheet presents — SwiftUI only
    /// supports one sheet transition at a time.
    private func handle(_ image: UIImage) {
        ReceiptHandoffService.stashPendingImage(image)
        source = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            appRouter.presentSheet(.addExpense(nil))
        }
    }
}

// MARK: - Camera picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Fall back to the photo library on devices without a camera (e.g. Simulator),
        // where requesting `.camera` would crash.
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
