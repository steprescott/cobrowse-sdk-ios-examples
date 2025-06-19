import UIKit
import AVFoundation

class CameraView: UIView {

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let previewQueue = DispatchQueue(label: "camera.frame.processing")

    private let imageView = UIImageView()
    private var currentPosition: AVCaptureDevice.Position = .front
    private var currentImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageView()
    }
    
    func start() {
        defer { session.commitConfiguration() }
        
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: currentPosition)
        else { return }

        if let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        if !session.outputs.contains(output), session.canAddOutput(output) {
            session.addOutput(output)
        }

        output.setSampleBufferDelegate(self, queue: previewQueue)
        output.alwaysDiscardsLateVideoFrames = true

        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func switchCamera() {
        currentPosition = (currentPosition == .back) ? .front : .back
        start()
    }

    func takePhoto() -> UIImage? {
        return currentImage
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(imageView)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            currentImage = uiImage

            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = uiImage
            }
        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    }
}
