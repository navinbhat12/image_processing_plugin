package dev.image_processing.image_processing_plugin

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class ImageProcessingPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var applicationContext: android.content.Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_processing_plugin")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "enhanceImage") {
      val imagePath = call.argument<String>("imagePath")

      if (imagePath == null) {
        result.error("INVALID_ARGUMENTS", "imagePath cannot be null", null)
        return
      }

      try {
        val originalBitmap = BitmapFactory.decodeFile(imagePath)
        if (originalBitmap == null) {
          result.error("IMAGE_LOAD_FAILED", "Could not decode image at path: $imagePath", null)
          return
        }

        // Apply enhancements
        val enhancedBitmap = applyAndroidEnhancements(originalBitmap)

        // Save enhanced image to a temporary file
        val filteredImagePath = saveBitmapToFile(enhancedBitmap, "enhanced_android_${UUID.randomUUID()}.jpg")

        if (filteredImagePath != null) {
          result.success(filteredImagePath)
        } else {
          result.error("SAVE_FAILED", "Failed to save enhanced image", null)
        }

      } catch (e: Exception) {
        result.error("IMAGE_PROCESSING_ERROR", "Failed to enhance image: ${e.message}", e.toString())
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // MARK: - Image Processing Helper

  private fun applyAndroidEnhancements(originalBitmap: Bitmap): Bitmap {
    val outputBitmap = Bitmap.createBitmap(originalBitmap.width, originalBitmap.height, originalBitmap.config!!)
    val canvas = Canvas(outputBitmap)
    val paint = Paint()
    val colorMatrix = ColorMatrix()

    // --- Only Shadow Reduction (via overall brightness lift) ---
    // A positive value for brightness (0 to 255) will lift darker tones.
    // This is the simplest way to make shadows less dark using ColorMatrix.
    val shadowLiftValue = 30f // Adjust this value (e.g., 10f to 50f)
    colorMatrix.set(floatArrayOf(
      1f, 0f, 0f, 0f, shadowLiftValue,  // Red offset
      0f, 1f, 0f, 0f, shadowLiftValue,  // Green offset
      0f, 0f, 1f, 0f, shadowLiftValue,  // Blue offset
      0f, 0f, 0f, 1f, 0f               // Alpha
    ))

    paint.colorFilter = ColorMatrixColorFilter(colorMatrix)
    canvas.drawBitmap(originalBitmap, 0f, 0f, paint)

    return outputBitmap
  }

  // MARK: - File Management Helper

  private fun saveBitmapToFile(bitmap: Bitmap, filename: String): String? {
    val cacheDir = File(applicationContext.cacheDir, "flutter_plugin_images")
    if (!cacheDir.exists()) {
      cacheDir.mkdirs()
    }
    val file = File(cacheDir, filename)
    try {
      FileOutputStream(file).use { out ->
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        return file.absolutePath
      }
    } catch (e: Exception) {
      e.printStackTrace()
      return null
    }
  }
}