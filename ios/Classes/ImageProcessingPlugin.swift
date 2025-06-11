import Flutter
import UIKit
import CoreImage // Import Core Image framework
import CoreImage.CIFilterBuiltins // For easier access to built-in filters

public class ImageProcessingPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_processing_plugin", binaryMessenger: registrar.messenger())
    let instance = ImageProcessingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "enhanceImage" {
      guard let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "imagePath cannot be null", details: nil))
        return
      }

      // We can add parameters for brightness, contrast, shadow here from Dart
      // For now, let's use fixed values as requested.
      let brightnessAdjustment: CGFloat = 0.15 // Adjust exposure value (0.1 to 0.5 for subtle to moderate)
      let contrastAdjustment: CGFloat = 1.15   // Adjust contrast (1.0 for no change, >1.0 for more contrast)
      let shadowReductionAmount: CGFloat = 0.65 // Adjust shadow amount (0.0 to 1.0, 1.0 lifts shadows most)


      do {
        guard let originalImage = UIImage(contentsOfFile: imagePath) else {
          result(FlutterError(code: "IMAGE_NOT_FOUND", message: "Could not load image at path: \(imagePath)", details: nil))
          return
        }

        let enhancedImage = try applyImageEnhancements(
            originalImage,
            brightness: brightnessAdjustment,
            contrast: contrastAdjustment,
            shadows: shadowReductionAmount
        )

        let filteredImagePath = saveImageToTemporaryDirectory(enhancedImage, filename: "enhanced_ios_\(UUID().uuidString).jpg")

        if let path = filteredImagePath {
            result(path)
        } else {
            result(FlutterError(code: "SAVE_FAILED", message: "Failed to save enhanced image", details: nil))
        }

      } catch let error as NSError {
        result(FlutterError(code: "IMAGE_PROCESSING_ERROR", message: "Failed to enhance image: \(error.localizedDescription)", details: error.debugDescription))
      }
    } else {
      // You might have other method calls here in the future
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Image Processing Helper

  private func applyImageEnhancements(_ originalImage: UIImage, brightness: CGFloat, contrast: CGFloat, shadows: CGFloat) throws -> UIImage {
    guard let ciImage = CIImage(image: originalImage) else {
      throw NSError(domain: "ImageProcessingPlugin", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create CIImage from UIImage"])
    }

    var outputCIImage = ciImage

    // 1. Increase Brightness (Exposure Adjustment) - COMMENTED OUT
    // let exposureFilter = CIFilter.exposureAdjust()
    // exposureFilter.inputImage = outputCIImage
    // exposureFilter.ev = Float(brightness) // Exposure Value
    // guard let exposureOutput = exposureFilter.outputImage else {
    //     throw NSError(domain: "ImageProcessingPlugin", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to apply exposure adjustment"])
    // }
    // outputCIImage = exposureOutput

    // 2. Increase Contrast - COMMENTED OUT
    // let colorControlsFilter = CIFilter.colorControls()
    // colorControlsFilter.inputImage = outputCIImage
    // colorControlsFilter.contrast = Float(contrast) // Adjust contrast
    // guard let contrastOutput = colorControlsFilter.outputImage else {
    //     throw NSError(domain: "ImageProcessingPlugin", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to apply contrast"])
    // }
    // outputCIImage = contrastOutput

    // 3. Reduce Shadows
    let highlightShadowFilter = CIFilter.highlightShadowAdjust()
    highlightShadowFilter.inputImage = outputCIImage
    highlightShadowFilter.shadowAmount = Float(shadows) // Adjust shadow amount (0.0 to 1.0, 1.0 lifts shadows most)
    // highlightShadowFilter.highlightAmount = 0.0 // You can also reduce highlights if needed
    guard let shadowOutput = highlightShadowFilter.outputImage else {
        throw NSError(domain: "ImageProcessingPlugin", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to apply shadow adjustment"])
    }
    outputCIImage = shadowOutput

    // Render the CIImage to a UIImage
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
      throw NSError(domain: "ImageProcessingPlugin", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from CIImage"])
    }

    return UIImage(cgImage: cgImage)
  }
  // MARK: - File Management Helper

  private func saveImageToTemporaryDirectory(_ image: UIImage, filename: String) -> String? {
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileURL = tempDirectory.appendingPathComponent(filename)
    do {
      try image.jpegData(compressionQuality: 0.9)?.write(to: fileURL)
      return fileURL.path
    } catch {
      print("Failed to save image to temporary directory: \(error)")
      return nil
    }
  }
}
