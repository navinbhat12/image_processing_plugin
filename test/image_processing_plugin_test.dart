import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_processing_plugin/image_processing_plugin.dart'; // Import your plugin
import 'package:image/image.dart' as img; // Needed for mock image data

void main() {
  const MethodChannel channel = MethodChannel('image_processing_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Set up a mock handler for MethodChannel calls.
    // This is crucial because unit tests don't run on a real device.
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'enhanceImage') {
        // For 'enhanceImage', we'll simulate returning a dummy path.
        return '/mock/path/to/enhanced_image.jpg';
      }
      return null; // For any other method calls not explicitly mocked
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('ImageProcessingPlugin Unit Tests', () {
    // Test for isImageAcceptable (Dart-only, no platform channel involved for this test)
    test('isImageAcceptable accepts bright image', () async {
      // Create a dummy bright image file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_bright_image.jpg');

      // Create a simple bright image bitmap (e.g., all white)
      final dummyImage = img.Image(width: 10, height: 10);
      for (int y = 0; y < dummyImage.height; y++) {
        for (int x = 0; x < dummyImage.width; x++) {
          dummyImage.setPixelRgb(x, y, 200, 200, 200); // Bright pixels
        }
      }
      await tempFile.writeAsBytes(img.encodeJpg(dummyImage));

      // Use the actual thresholds from your ImageProcessingPlugin.isImageAcceptable
      // avgBrightness < 25 && darkRatio > 0.55
      // Bright image (avg 200, darkRatio 0.0) should be acceptable.
      expect(await ImageProcessingPlugin.isImageAcceptable(tempFile), true);

      tempFile.deleteSync();
    });

    test(
      'isImageAcceptable rejects very dark image (based on output example)',
      () async {
        // Create a dummy dark image file that should trigger rejection
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_dark_image.jpg');

        // Create an image that results in avgBrightness: 18, darkRatio: 0.57 (or similar)
        final dummyImage = img.Image(width: 10, height: 10);
        for (int y = 0; y < dummyImage.height; y++) {
          for (int x = 0; x < dummyImage.width; x++) {
            if ((x + y) % 3 == 0) {
              // Simulate very dark pixels to get a high darkRatio
              dummyImage.setPixelRgb(x, y, 10, 10, 10); // Brightness ~10
            } else {
              dummyImage.setPixelRgb(x, y, 20, 20, 20); // Brightness ~20
            }
          }
        }
        await tempFile.writeAsBytes(img.encodeJpg(dummyImage));

        // Based on your thresholds (avgBrightness < 25 && darkRatio > 0.55)
        // For avg 18, darkRatio 0.57, this should be false (rejected)
        expect(await ImageProcessingPlugin.isImageAcceptable(tempFile), false);

        tempFile.deleteSync();
      },
    );

    // Test for enhanceImage (involves platform channel mocking)
    test('enhanceImage returns a file path from native call', () async {
      final originalFile = File(
        '/path/to/some/original.jpg',
      ); // Mock a file path
      final resultFile = await ImageProcessingPlugin.enhanceImage(originalFile);
      expect(resultFile, isA<File>());
      expect(
        resultFile.path,
        '/mock/path/to/enhanced_image.jpg',
      ); // Expect mocked path
    });
  });
}
