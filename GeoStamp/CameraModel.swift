import AVFoundation
import UIKit

import SwiftUI
final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var lastImage: UIImage?
    @Published var flashOn = false
    @Published var zoom: CGFloat = 1

    private let output = AVCapturePhotoOutput()
    private var configured = false
    private var position: AVCaptureDevice.Position = .back
    private var device: AVCaptureDevice?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self?.configure()
                if !(self?.session.isRunning ?? false) {
                    self?.session.startRunning()
                }
            }
        }
    }

    private func configure() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let input = try? AVCaptureDeviceInput(device: device) {
            self.device = device
            if session.canAddInput(input) { session.addInput(input) }
        }

        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashOn ? .on : .off
        output.capturePhoto(with: settings, delegate: self)
    }

    func setZoom(_ value: CGFloat) {
        let value = min(max(value, 1), device?.activeFormat.videoMaxZoomFactor ?? 5)
        do {
            try device?.lockForConfiguration()
            device?.videoZoomFactor = value
            device?.unlockForConfiguration()
            zoom = value
        } catch {}
    }

    func toggleCamera() {
        guard let newDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position == .back ? .front : .back
        ),
        let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }

        session.beginConfiguration()
        if let old = session.inputs.first { session.removeInput(old) }
        if session.canAddInput(newInput) { session.addInput(newInput) }
        device = newDevice
        position = position == .back ? .front : .back
        session.commitConfiguration()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.lastImage = image }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
