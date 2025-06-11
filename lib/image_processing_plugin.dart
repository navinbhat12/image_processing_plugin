import 'dart:io';
import 'package:flutter/services.dart'; // REQUIRED for MethodChannel
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
// REMOVED: import 'package:flutter_image_filters/flutter_image_filters.dart';
// REMOVED: import 'package:path_provider/path_provider.dart';

class ImageProcessingPlugin {
  // MethodChannel to communicate with native platform code
  static const MethodChannel _channel = MethodChannel(
    'image_processing_plugin',
  );

  /// Detects whether any face is present in the given image file.
  static Future<bool> detectFaceInImage(File imageFile) async {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    );

    final faceDetector = FaceDetector(options: options);
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    return faces.isNotEmpty;
  }

  /// Checks if image is acceptably bright and not too dark or flat.
  static Future<bool> isImageAcceptable(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return false;

    final pixels = decoded.width * decoded.height;
    int totalBrightness = 0;
    int veryDarkPixels = 0;

    for (int y = 0; y < decoded.height; y++) {
      for (int x = 0; x < decoded.width; x++) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        final brightness = ((r + g + b) / 3).round();
        totalBrightness += brightness;

        if (brightness < 25) veryDarkPixels++;
      }
    }

    final avgBrightness = totalBrightness ~/ pixels;
    final darkRatio = veryDarkPixels / pixels;

    // --- REMOVED PRINT STATEMENTS ---
    // print('Image Acceptability Check:');
    // print('  Average Brightness: $avgBrightness');
    // print(
    //   '  Dark Pixel Ratio (brightness < 25): ${darkRatio.toStringAsFixed(2)}',
    // );
    // print('  Current Thresholds: avgBrightness < 35 && darkRatio > 0.5');
    // --------------------------------

    final tooDark = avgBrightness < 35 && darkRatio > 0.5;

    return !tooDark;
  }

  /// Applies final aesthetic filters for consistent display in grid using native code.
  /// Enhances brightness, reduces shadows, and increases contrast.
  static Future<File> enhanceImage(File originalImage) async {
    try {
      final String? enhancedImagePath = await _channel.invokeMethod(
        'enhanceImage', // This calls the native method named 'enhanceImage'
        <String, dynamic>{
          'imagePath': originalImage.path,
          // You can also pass parameters for tuning filters to native code here
          // For now, fixed values are used in native Swift/Kotlin code
        },
      );

      if (enhancedImagePath != null) {
        return File(enhancedImagePath);
      } else {
        // If native enhancement fails or returns null, return the original image
        /*print("Native enhancement returned null, returning original image.");*/
        return originalImage;
      }
    } on PlatformException catch (_) {
      // CHANGED catch (e) to catch (_)
      /*print(
        "Failed to invoke native enhanceImage: '${e.message}'. Returning original image.",
      );*/
      return originalImage;
    } catch (_) {
      // CHANGED catch (e) to catch (_)
      /* print(
        "An unexpected error occurred during enhanceImage: $e. Returning original image.",
      );*/
      return originalImage;
    }
  }
}
