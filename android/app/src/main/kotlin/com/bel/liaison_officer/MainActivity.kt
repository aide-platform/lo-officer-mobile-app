package com.bel.liaison_officer

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> save(call, result)
                    "open" -> open(call, result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "check" -> result.success(DeviceIntegrity.check(this))
                    else -> result.notImplemented()
                }
            }
    }

    // minSdk is 29 (Android 10), so files always go through MediaStore:
    // no storage permission and no direct file paths.
    private fun save(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val rawName = call.argument<String>("name")
        val mime = call.argument<String>("mime") ?: "application/octet-stream"
        if (bytes == null || rawName.isNullOrBlank()) {
            result.error("BAD_ARGS", "File name and bytes are required.", null)
            return
        }
        // Names can come from the server (help desk attachments), so never
        // let one carry a folder path.
        val name = safeFileName(rawName)
        try {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create the file in Downloads.")
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not write the file in Downloads.")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            result.success(uri.toString())
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message ?: "Could not save the file.", null)
        }
    }

    private fun open(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val mime = call.argument<String>("mime") ?: "*/*"
        if (uri.isNullOrBlank()) {
            result.success(false)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uri), mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.success(false)
        }
    }

    /**
     * Last path segment only, with characters that are unsafe in file names
     * replaced. Falls back to "download" when nothing usable is left.
     */
    private fun safeFileName(raw: String): String {
        val last = raw.replace('\\', '/').substringAfterLast('/')
        val cleaned = last
            .replace(Regex("[\\u0000-\\u001F:*?\"<>|]"), "_")
            .trim()
            .trimStart('.')
            .take(150)
        return cleaned.ifBlank { "download" }
    }

    private companion object {
        const val CHANNEL = "com.bel.liaison_officer/downloads"
        const val SECURITY_CHANNEL = "com.bel.liaison_officer/security"
    }
}
