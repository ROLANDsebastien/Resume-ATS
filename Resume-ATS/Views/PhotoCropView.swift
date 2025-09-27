import SwiftUI

struct PhotoCropView: View {
    @Binding var croppedData: Data?
    @Environment(\.dismiss) var dismiss

    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0

    private let cropSize: CGFloat = 200
    private let viewSize: CGFloat = 300

    var body: some View {
        VStack {
            ZStack {
                if let imageData = croppedData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: viewSize * scale, height: viewSize * scale)
                        .offset(offset)
                        .clipped()
                }

                // Crop frame
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
            }
            .frame(width: viewSize, height: viewSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )

            HStack {
                Button("Annuler") {
                    dismiss()
                }
                Spacer()
                Button("Rogner") {
                    cropImage()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }

    private func cropImage() {
        guard let imageData = croppedData, let nsImage = NSImage(data: imageData) else { return }

        let imageSize = nsImage.size
        let scaleX = imageSize.width / (viewSize * scale)
        let scaleY = imageSize.height / (viewSize * scale)

        // Calculate crop size in image coordinates, making it square
        let cropSizeInImage = min(cropSize * scaleX, cropSize * scaleY)

        let cropRect = CGRect(
            x: (viewSize / 2 - cropSize / 2 - offset.width) * scaleX,
            y: (viewSize / 2 - cropSize / 2 - offset.height) * scaleY,
            width: cropSizeInImage,
            height: cropSizeInImage
        )

        if let croppedImage = cropImage(nsImage, to: cropRect),
            let data = croppedImage.tiffRepresentation
        {
            croppedData = data
        }
    }

    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        // Clamp the rect to image bounds
        let clampedX = max(0, min(rect.origin.x, image.size.width - rect.size.width))
        let clampedY = max(0, min(rect.origin.y, image.size.height - rect.size.height))
        let clampedRect = CGRect(
            x: clampedX, y: clampedY, width: rect.size.width, height: rect.size.height)

        let scaleFactor = CGFloat(cgImage.width) / image.size.width
        let pixelRect = CGRect(
            x: clampedRect.origin.x * scaleFactor,
            y: clampedRect.origin.y * scaleFactor,
            width: clampedRect.size.width * scaleFactor,
            height: clampedRect.size.height * scaleFactor
        )

        let croppedCGImage = cgImage.cropping(to: pixelRect)
        guard let croppedCGImage = croppedCGImage else { return nil }

        let croppedImage = NSImage(
            cgImage: croppedCGImage,
            size: NSSize(width: clampedRect.size.width, height: clampedRect.size.height))
        return croppedImage
    }
}
