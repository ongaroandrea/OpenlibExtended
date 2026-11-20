package dev.wath.openlibextended

import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.view.KeyEvent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    // Volume keys as page keys: only while a reader screen has turned it on
    // over "openlib/page_keys", so the volume keys work normally elsewhere.
    private var pageKeysChannel: MethodChannel? = null
    private var volumeKeyPaging = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pageKeysChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "openlib/page_keys").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "setVolumeKeyPaging") {
                    volumeKeyPaging = call.arguments as? Boolean ?: false
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "openlib/readers")
            .setMethodCallHandler { call, result ->
                try {
                    val mime = call.argument<String>("mimeType")
                    require(mime == "application/epub+zip" || mime == "application/pdf")
                    when (call.method) {
                        "readers" -> result.success(readers(mime!!))
                        "open" -> {
                            val file = File(call.argument<String>("path") ?: "")
                            require(file.isFile) { "The book file could not be found." }
                            val reader = call.argument<String>("reader") ?: "ask"
                            // The app already declares this FileProvider with
                            // the same roots, so do not depend on the private
                            // authority owned by the open_file plugin.
                            val uri = FileProvider.getUriForFile(this,
                                "$packageName.fileprovider", file)
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mime)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                clipData = ClipData.newRawUri("Book", uri)
                                if (reader != "ask") setPackage(reader)
                            }
                            startActivity(if (reader == "ask")
                                Intent.createChooser(intent, null) else intent)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("reader_unavailable", e.message, null)
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        pageKeysChannel?.setMethodCallHandler(null)
        pageKeysChannel = null
        volumeKeyPaging = false
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        if (volumeKeyPaging &&
            (code == KeyEvent.KEYCODE_VOLUME_DOWN || code == KeyEvent.KEYCODE_VOLUME_UP)) {
            // Swallow both down and up so the volume doesn't change; turn
            // the page on down (repeats while held).
            if (event.action == KeyEvent.ACTION_DOWN) {
                pageKeysChannel?.invokeMethod("pageKey",
                    if (code == KeyEvent.KEYCODE_VOLUME_DOWN) "next" else "previous")
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    @Suppress("DEPRECATION")
    private fun readers(mime: String): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse("content://openlib/book"), mime)
        }
        return packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            .filter { it.activityInfo.packageName != packageName }
            .distinctBy { it.activityInfo.packageName }
            .map { mapOf("id" to it.activityInfo.packageName,
                "label" to it.activityInfo.applicationInfo.loadLabel(packageManager).toString()) }
            .sortedBy { it["label"]!!.lowercase() }
    }
}
