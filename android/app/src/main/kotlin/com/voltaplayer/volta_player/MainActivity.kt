package com.voltaplayer.volta_player

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.media.MediaScannerConnection
import android.provider.MediaStore
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.ffmpeg.FFmpeg
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.voltaplayer.volta_player/youtubedl"
    private val EVENT_CHANNEL = "com.voltaplayer.volta_player/youtubedl_events"
    private val STORAGE_CHANNEL = "com.voltaplayer.volta_player/storage"
    private val PREFS = "volta_player_prefs"
    private val DOWNLOAD_PATH_KEY = "download_path"
    private val DOWNLOAD_TREE_URI_KEY = "download_tree_uri"
    private val PICK_DOWNLOAD_DIR_REQUEST = 6107
    private val PICK_MEDIA_REQUEST = 6108
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPathPickResult: MethodChannel.Result? = null
    private var pendingMediaPickResult: MethodChannel.Result? = null
    private val activeDownloads = mutableMapOf<String, Job>()
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    private fun defaultDownloadPath(): String {
        return File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "Volta Player"
        ).absolutePath
    }

    private fun getSavedDownloadPath(): String {
        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        return prefs.getString(DOWNLOAD_PATH_KEY, null)?.takeIf { it.isNotBlank() } ?: defaultDownloadPath()
    }

    private fun getSavedTreeUri(): Uri? {
        val saved = getSharedPreferences(PREFS, MODE_PRIVATE)
            .getString(DOWNLOAD_TREE_URI_KEY, null)
            ?.takeIf { it.isNotBlank() }
        return saved?.let { Uri.parse(it) }
    }

    private fun saveDownloadPath(path: String): String {
        val cleanPath = path.trim().ifBlank { defaultDownloadPath() }
        val dir = File(cleanPath)
        if (!dir.exists()) dir.mkdirs()
        getSharedPreferences(PREFS, MODE_PRIVATE)
            .edit()
            .putString(DOWNLOAD_PATH_KEY, dir.absolutePath)
            .remove(DOWNLOAD_TREE_URI_KEY)
            .apply()
        return dir.absolutePath
    }

    private fun saveDownloadTree(uri: Uri, displayPath: String): String {
        getSharedPreferences(PREFS, MODE_PRIVATE)
            .edit()
            .putString(DOWNLOAD_TREE_URI_KEY, uri.toString())
            .putString(DOWNLOAD_PATH_KEY, displayPath)
            .apply()
        return displayPath
    }

    private fun treeUriToFilePath(uri: Uri): String? {
        val treeId = DocumentsContract.getTreeDocumentId(uri)
        if (!treeId.startsWith("primary:")) return null
        val relativePath = treeId.removePrefix("primary:").trim('/')
        val root = Environment.getExternalStorageDirectory().absolutePath
        return if (relativePath.isBlank()) root else File(root, relativePath).absolutePath
    }

    private fun mimeForFile(file: File): String {
        val extension = file.extension.lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: when (extension) {
                "mp3" -> "audio/mpeg"
                "m4a" -> "audio/mp4"
                "aac" -> "audio/aac"
                "opus" -> "audio/opus"
                "ogg" -> "audio/ogg"
                "wav" -> "audio/wav"
                "flac" -> "audio/flac"
                "mp4" -> "video/mp4"
                "mkv" -> "video/x-matroska"
                "webm" -> "video/webm"
                else -> "application/octet-stream"
            }
    }

    private fun mediaTypeForName(name: String): String {
        val extension = name.substringAfterLast('.', "").lowercase()
        return when (extension) {
            "mp4", "mkv", "webm", "mov", "m4v" -> "video"
            else -> "audio"
        }
    }

    private fun documentUriForTree(treeUri: Uri): Uri {
        return DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )
    }

    private fun copyFileToUri(file: File, destination: Uri) {
        contentResolver.openOutputStream(destination)?.use { output ->
            file.inputStream().use { input -> input.copyTo(output) }
        } ?: throw IllegalStateException("Could not open destination file")
    }

    private fun copyUriToFile(uri: Uri, destination: File): Long {
        destination.parentFile?.let { parent ->
            if (!parent.exists()) parent.mkdirs()
        }
        var bytes = 0L
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(destination).use { output ->
                bytes = input.copyTo(output)
            }
        } ?: throw IllegalStateException("Could not open selected media")
        return bytes
    }

    private fun displayNameForUri(uri: Uri): String {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex("_display_name")
            if (nameIndex >= 0 && cursor.moveToFirst()) {
                return cursor.getString(nameIndex)
            }
        }
        return "media_${System.currentTimeMillis()}"
    }

    private fun publishToSelectedFolder(file: File): Pair<String, Uri?> {
        val treeUri = getSavedTreeUri()
        if (treeUri != null) {
            val parentDocumentUri = documentUriForTree(treeUri)
            val destination = DocumentsContract.createDocument(
                contentResolver,
                parentDocumentUri,
                mimeForFile(file),
                file.name
            ) ?: throw IllegalStateException("Could not create file in selected folder")
            copyFileToUri(file, destination)
            return Pair("${getSavedDownloadPath()}/${file.name}", destination)
        }

        val publicDir = File(defaultDownloadPath())
        if (!publicDir.exists()) publicDir.mkdirs()
        val destinationFile = File(publicDir, file.name)
        file.copyTo(destinationFile, overwrite = true)
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(destinationFile.absolutePath),
            arrayOf(mimeForFile(destinationFile)),
            null
        )
        return Pair(destinationFile.absolutePath, Uri.fromFile(destinationFile))
    }

    private fun workDownloadDirectory(): File {
        val dir = File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "VoltaWork")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun updateYoutubeDLOrThrow() {
        try {
            YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel.STABLE)
        } catch (e: Exception) {
            try {
                YoutubeDL.getInstance().updateYoutubeDL(applicationContext)
            } catch (e2: Exception) {
                throw IllegalStateException(
                    "yt-dlp update failed. Check internet connection and try again. ${e2.message ?: e.message}",
                    e2
                )
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_MEDIA_REQUEST) {
            handleMediaPickResult(resultCode, data)
            return
        }

        if (requestCode != PICK_DOWNLOAD_DIR_REQUEST) return

        val result = pendingPathPickResult
        pendingPathPickResult = null

        if (result == null) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val uri = data.data!!
        val flags = data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: Exception) {
        }

        val path = treeUriToFilePath(uri) ?: uri.toString()
        result.success(saveDownloadTree(uri, path))
    }

    private fun handleMediaPickResult(resultCode: Int, data: Intent?) {
        val result = pendingMediaPickResult
        pendingMediaPickResult = null
        if (result == null) return
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, Any>>())
            return
        }

        scope.launch(Dispatchers.IO) {
            try {
                val uris = mutableListOf<Uri>()
                data.clipData?.let { clip ->
                    for (index in 0 until clip.itemCount) {
                        uris.add(clip.getItemAt(index).uri)
                    }
                }
                data.data?.let { uris.add(it) }

                val imported = uris.mapNotNull { uri ->
                    val fileName = displayNameForUri(uri)
                    val tempFile = File(workDownloadDirectory(), fileName)
                    val size = copyUriToFile(uri, tempFile)
                    val published = publishToSelectedFolder(tempFile)
                    mapOf(
                        "path" to tempFile.absolutePath,
                        "publishedPath" to published.first,
                        "title" to fileName.substringBeforeLast('.'),
                        "type" to mediaTypeForName(fileName),
                        "size" to size
                    )
                }
                launch(Dispatchers.Main) { result.success(imported) }
            } catch (e: Exception) {
                launch(Dispatchers.Main) {
                    result.error("IMPORT_FAILED", e.message, null)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            YoutubeDL.getInstance().init(applicationContext)
            FFmpeg.getInstance().init(applicationContext)
            
            // Auto-update yt-dlp to latest version on launch to fix outdated signature issues
            scope.launch(Dispatchers.IO) {
                try {
                    YoutubeDL.getInstance().updateYoutubeDL(applicationContext, YoutubeDL.UpdateChannel.STABLE)
                } catch (e: Exception) {
                    try {
                        YoutubeDL.getInstance().updateYoutubeDL(applicationContext)
                    } catch (e2: Exception) {
                        e2.printStackTrace()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDownloadPath" -> {
                    result.success(saveDownloadPath(getSavedDownloadPath()))
                }
                "setDownloadPath" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(saveDownloadPath(path))
                }
                "resetDownloadPath" -> {
                    result.success(saveDownloadPath(defaultDownloadPath()))
                }
                "pickDownloadPath" -> {
                    if (pendingPathPickResult != null) {
                        result.error("PICKER_ACTIVE", "A folder picker is already open.", null)
                        return@setMethodCallHandler
                    }
                    pendingPathPickResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                    }
                    startActivityForResult(intent, PICK_DOWNLOAD_DIR_REQUEST)
                }
                "pickMediaFiles" -> {
                    if (pendingMediaPickResult != null) {
                        result.error("PICKER_ACTIVE", "A media picker is already open.", null)
                        return@setMethodCallHandler
                    }
                    pendingMediaPickResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("audio/*", "video/*"))
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    }
                    startActivityForResult(intent, PICK_MEDIA_REQUEST)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "download" -> {
                    val url = call.argument<String>("url") ?: return@setMethodCallHandler
                    val taskId = call.argument<String>("taskId") ?: return@setMethodCallHandler
                    val format = call.argument<String>("format") ?: "best"
                    val requestedOutputDir = call.argument<String>("outputDir")
                    
                    val job = scope.launch(Dispatchers.IO) {
                        try {
                            val request = YoutubeDLRequest(url)
                            val outDir = workDownloadDirectory()
                            if (!outDir.exists()) outDir.mkdirs()

                            request.addOption("-o", "${outDir.absolutePath}/%(title)s.%(ext)s")
                            request.addOption("--newline")
                            request.addOption("--no-playlist")
                            request.addOption("--restrict-filenames")
                            request.addOption("--no-warnings")
                            
                            if (format == "audioOnly") {
                                request.addOption("-x")
                                request.addOption("--audio-format", "mp3")
                                request.addOption("--audio-quality", "0")
                            } else if (format == "videoMp4") {
                                request.addOption("-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4")
                            } else {
                                request.addOption("-f", "bestvideo+bestaudio/best")
                            }

                            YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                                launch(Dispatchers.Main) {
                                    eventSink?.success(mapOf(
                                        "taskId" to taskId,
                                        "progress" to (progress / 100.0),
                                        "eta" to etaInSeconds.toString(),
                                        "speed" to line
                                    ))
                                }
                            }

                            val newestFile = outDir
                                .listFiles()
                                ?.filter { it.isFile }
                                ?.maxByOrNull { it.lastModified() }

                            val publishedPath = newestFile?.let { publishToSelectedFolder(it).first } ?: ""
                            
                            launch(Dispatchers.Main) {
                                eventSink?.success(mapOf(
                                    "taskId" to taskId,
                                    "progress" to 1.0,
                                    "status" to "done",
                                    "filePath" to publishedPath
                                ))
                            }
                        } catch (e: Exception) {
                            launch(Dispatchers.Main) {
                                eventSink?.success(mapOf(
                                    "taskId" to taskId,
                                    "error" to e.message
                                ))
                            }
                        }
                    }
                    activeDownloads[taskId] = job
                    result.success(null)
                }
                "updateYtdlp" -> {
                    scope.launch(Dispatchers.IO) {
                        try {
                            updateYoutubeDLOrThrow()
                            launch(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            launch(Dispatchers.Main) {
                                result.error("YTDLP_UPDATE_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "cancel" -> {
                    val taskId = call.argument<String>("taskId") ?: return@setMethodCallHandler
                    try {
                        YoutubeDL.getInstance().destroyProcessById(taskId)
                        activeDownloads[taskId]?.cancel()
                        activeDownloads.remove(taskId)
                        result.success(null)
                    } catch(e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
