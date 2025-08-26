// plugins/image_gallery_saver/android/src/main/kotlin/com/example/imagegallerysaver/ImageGallerySaverPlugin.kt

package com.example.imagegallerysaver

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.text.TextUtils
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class ImageGallerySaverPlugin : FlutterPlugin, MethodCallHandler {
    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null

    // --- Única implementación de onAttachedToEngine (embedding v2) ---
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "image_gallery_saver")
        methodChannel!!.setMethodCallHandler(this)
    }

    // --- Única implementación de onDetachedFromEngine (embedding v2) ---
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes") ?: return
                val quality = call.argument<Int>("quality") ?: return
                val name = call.argument<String>("name")
                result.success(
                    saveImageToGallery(
                        BitmapFactory.decodeByteArray(image, 0, image.size),
                        quality,
                        name
                    )
                )
            }
            "saveFileToGallery" -> {
                val path = call.argument<String>("file") ?: return
                val name = call.argument<String>("name")
                result.success(saveFileToGallery(path, name))
            }
            else -> result.notImplemented()
        }
    }

    private fun generateUri(extension: String = "", name: String? = null): Uri {
        val fileName = name ?: System.currentTimeMillis().toString()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                getMIMEType(extension)?.let {
                    put(MediaStore.Images.Media.MIME_TYPE, it)
                    if (it.startsWith("video")) {
                        uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_MOVIES)
                    }
                }
            }
            return applicationContext!!.contentResolver.insert(uri, values)!!
        } else {
            val storePath =
                Environment.getExternalStorageDirectory().absolutePath + File.separator + Environment.DIRECTORY_PICTURES
            val appDir = File(storePath)
            if (!appDir.exists()) appDir.mkdir()
            val fileWithExt = if (extension.isNotEmpty()) "$fileName.$extension" else fileName
            return Uri.fromFile(File(appDir, fileWithExt))
        }
    }

    private fun getMIMEType(extension: String): String? {
        return if (extension.isNotEmpty()) {
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
        } else null
    }

    private fun saveImageToGallery(bmp: Bitmap, quality: Int, name: String?): HashMap<String, Any?> {
        val context = applicationContext!!
        val fileUri = generateUri("jpg", name)
        return try {
            context.contentResolver.openOutputStream(fileUri)!!.use { fos ->
                bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
                fos.flush()
            }
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
            bmp.recycle()
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } catch (e: IOException) {
            SaveResultModel(false, null, e.toString()).toHashMap()
        }
    }

    private fun saveFileToGallery(filePath: String, name: String?): HashMap<String, Any?> {
        val context = applicationContext!!
        return try {
            val originalFile = File(filePath)
            val fileUri = generateUri(originalFile.extension, name)
            context.contentResolver.openOutputStream(fileUri)!!.use { outputStream ->
                FileInputStream(originalFile).use { fileInputStream ->
                    val buffer = ByteArray(10240)
                    var count: Int
                    while (fileInputStream.read(buffer).also { count = it } > 0) {
                        outputStream.write(buffer, 0, count)
                    }
                }
                outputStream.flush()
            }
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, fileUri))
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } catch (e: IOException) {
            SaveResultModel(false, null, e.toString()).toHashMap()
        }
    }
}

class SaveResultModel(
    var isSuccess: Boolean,
    var filePath: String? = null,
    var errorMessage: String? = null
) {
    fun toHashMap(): HashMap<String, Any?> {
        return hashMapOf(
            "isSuccess" to isSuccess,
            "filePath" to filePath,
            "errorMessage" to errorMessage
        )
    }
}
