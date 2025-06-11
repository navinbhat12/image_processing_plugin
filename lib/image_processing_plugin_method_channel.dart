import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_processing_plugin_platform_interface.dart';

/// An implementation of [ImageProcessingPluginPlatform] that uses method channels.
class MethodChannelImageProcessingPlugin extends ImageProcessingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('image_processing_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
