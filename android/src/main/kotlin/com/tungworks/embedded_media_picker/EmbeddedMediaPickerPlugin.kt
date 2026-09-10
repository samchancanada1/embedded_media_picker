package com.tungworks.embedded_media_picker

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.ext.SdkExtensions
import android.provider.OpenableColumns
import android.provider.MediaStore
import android.view.Gravity
import android.view.View
import android.webkit.MimeTypeMap
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.photopicker.EmbeddedPhotoPickerFeatureInfo
import android.widget.photopicker.EmbeddedPhotoPickerSession
import androidx.photopicker.EmbeddedPhotoPickerView
import androidx.photopicker.ExperimentalPhotoPickerApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class EmbeddedMediaPickerPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var pendingPickResult: Result? = null
    private var pendingPickOptions: PickerOptions? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            EmbeddedMediaPickerViewFactory(binding.binaryMessenger),
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isEmbeddedPickerAvailable" -> result.success(EmbeddedPhotoPickerCapability.isAvailable())
            "pickMedia" -> pickMedia(call.arguments as? Map<*, *>, result)
            else -> result.notImplemented()
        }
    }

    private fun pickMedia(arguments: Map<*, *>?, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "No foreground Android Activity is attached.", null)
            return
        }
        if (pendingPickResult != null) {
            result.error("already_active", "A media picker request is already active.", null)
            return
        }

        val options = PickerOptions.from(arguments)
        val intent = buildClassicPickerIntent(options)
        pendingPickResult = result
        pendingPickOptions = options
        try {
            currentActivity.startActivityForResult(intent, PICK_MEDIA_REQUEST_CODE)
        } catch (exception: Exception) {
            pendingPickResult = null
            pendingPickOptions = null
            result.error("launch_failed", exception.localizedMessage ?: "Failed to launch media picker.", null)
        }
    }

    private fun buildClassicPickerIntent(options: PickerOptions): Intent {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                type = options.intentMimeType
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                if (options.maxSelectionLimit > 1) {
                    val cappedLimit = options.maxSelectionLimit.coerceAtMost(
                        MediaStore.getPickImagesMaxLimit(),
                    )
                    putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, cappedLimit)
                }
            }
        }

        return Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = options.intentMimeType
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, options.maxSelectionLimit != 1)
            if (options.mimeTypes.isNotEmpty()) {
                putExtra(Intent.EXTRA_MIME_TYPES, options.mimeTypes.toTypedArray())
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_MEDIA_REQUEST_CODE) {
            return false
        }

        val result = pendingPickResult ?: return true
        pendingPickResult = null
        val options = pendingPickOptions ?: PickerOptions.from(null)
        pendingPickOptions = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(emptyList<Map<String, Any?>>())
            return true
        }

        val uris = mutableListOf<Uri>()
        data?.clipData?.let { clipData ->
            for (index in 0 until clipData.itemCount) {
                clipData.getItemAt(index)?.uri?.let { uris.add(it) }
            }
        }
        data?.data?.let { uris.add(it) }

        if (options.persistablePermissions) {
            val flags = data?.flags ?: 0
            val takeFlags = flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            if (takeFlags != 0) {
                uris.distinct().forEach { uri ->
                    runCatching {
                        currentContentResolver().takePersistableUriPermission(uri, takeFlags)
                    }
                }
            }
        }

        result.success(
            uris
                .distinct()
                .map { uri ->
                    MediaItem.fromUri(
                        resolver = currentContentResolver(),
                        uri = uri,
                        isTemporary = false,
                    ).toMap()
                },
        )
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    private fun currentContentResolver(): ContentResolver {
        return activity?.contentResolver ?: applicationContext!!.contentResolver
    }

    private companion object {
        const val CHANNEL_NAME = "embedded_media_picker"
        const val VIEW_TYPE = "embedded_media_picker/view"
        const val PICK_MEDIA_REQUEST_CODE = 7481
    }
}

private data class PickerOptions(
    val mediaType: String,
    val maxSelectionLimit: Int,
    val mimeTypes: List<String>,
    val preselectedUris: List<Uri>,
    val orderedSelection: Boolean,
    val accentColorArgb: Long?,
    val theme: String,
    val persistablePermissions: Boolean,
) {
    val intentMimeType: String
        get() = when {
            mimeTypes.size == 1 -> mimeTypes.first()
            mediaType == "image" -> "image/*"
            mediaType == "video" -> "video/*"
            else -> "*/*"
        }

    companion object {
        fun from(arguments: Map<*, *>?): PickerOptions {
            val mimeTypes = (arguments?.get("mimeTypes") as? List<*>)
                ?.filterIsInstance<String>()
                ?: emptyList()
            val preselectedUris = (arguments?.get("preselectedUris") as? List<*>)
                ?.filterIsInstance<String>()
                ?.map(Uri::parse)
                ?: emptyList()
            return PickerOptions(
                mediaType = arguments?.get("mediaType") as? String ?: "imageAndVideo",
                maxSelectionLimit = (arguments?.get("maxSelectionLimit") as? Number)
                    ?.toInt()
                    ?.coerceAtLeast(1)
                    ?: 1,
                mimeTypes = mimeTypes,
                preselectedUris = preselectedUris,
                orderedSelection = arguments?.get("orderedSelection") as? Boolean ?: false,
                accentColorArgb = (arguments?.get("accentColorArgb") as? Number)?.toLong(),
                theme = arguments?.get("theme") as? String ?: "system",
                persistablePermissions = arguments?.get("persistablePermissions") as? Boolean ?: false,
            )
        }
    }
}

private data class MediaItem(
    val uri: Uri,
    val type: String,
    val mimeType: String?,
    val fileName: String?,
    val sizeBytes: Long?,
    val isTemporary: Boolean,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "uri" to uri.toString(),
            "type" to type,
            "mimeType" to mimeType,
            "fileName" to fileName,
            "sizeBytes" to sizeBytes,
            "isTemporary" to isTemporary,
        )
    }

    companion object {
        fun fromUri(
            resolver: ContentResolver,
            uri: Uri,
            isTemporary: Boolean,
        ): MediaItem {
            val mimeType = resolver.getType(uri) ?: mimeTypeFromExtension(uri)
            val metadata = queryOpenableMetadata(resolver, uri)
            return MediaItem(
                uri = uri,
                type = typeFromMime(mimeType),
                mimeType = mimeType,
                fileName = metadata.fileName ?: uri.lastPathSegment,
                sizeBytes = metadata.sizeBytes,
                isTemporary = isTemporary,
            )
        }

        private fun typeFromMime(mimeType: String?): String {
            return when {
                mimeType?.startsWith("image/") == true -> "image"
                mimeType?.startsWith("video/") == true -> "video"
                else -> "unknown"
            }
        }

        private fun mimeTypeFromExtension(uri: Uri): String? {
            val extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString())
            if (extension.isNullOrBlank()) {
                return null
            }
            return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
        }

        private fun queryOpenableMetadata(
            resolver: ContentResolver,
            uri: Uri,
        ): OpenableMetadata {
            var cursor: Cursor? = null
            return try {
                cursor = resolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                    null,
                    null,
                    null,
                )
                if (cursor != null && cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    OpenableMetadata(
                        fileName = if (nameIndex >= 0 && !cursor.isNull(nameIndex)) {
                            cursor.getString(nameIndex)
                        } else {
                            null
                        },
                        sizeBytes = if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                            cursor.getLong(sizeIndex)
                        } else {
                            null
                        },
                    )
                } else {
                    OpenableMetadata()
                }
            } catch (_: Exception) {
                OpenableMetadata()
            } finally {
                cursor?.close()
            }
        }
    }
}

private data class OpenableMetadata(
    val fileName: String? = null,
    val sizeBytes: Long? = null,
)

private object EmbeddedPhotoPickerCapability {
    fun isAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            SdkExtensions.getExtensionVersion(Build.VERSION_CODES.UPSIDE_DOWN_CAKE) >= 15
    }
}

private class EmbeddedMediaPickerViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView {
        return EmbeddedMediaPickerPlatformView(
            context = context,
            messenger = messenger,
            viewId = viewId,
            arguments = args as? Map<*, *>,
        )
    }
}

@OptIn(ExperimentalPhotoPickerApi::class)
private class EmbeddedMediaPickerPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    arguments: Map<*, *>?,
) : PlatformView {
    private val channel = MethodChannel(messenger, "embedded_media_picker/view_$viewId")
    private val options = PickerOptions.from(arguments)
    private val contentView: View
    private var embeddedPickerView: EmbeddedPhotoPickerView? = null
    private var listener: EmbeddedPhotoPickerView.EmbeddedPhotoPickerStateChangeListener? = null

    init {
        contentView = if (EmbeddedPhotoPickerCapability.isAvailable()) {
            runCatching { createEmbeddedPickerView(context) }.getOrElse { throwable ->
                createUnsupportedView(context).also {
                    channel.invokeMethod(
                        "unsupported",
                        mapOf(
                            "code" to "embedded_picker_unavailable",
                            "message" to (throwable.localizedMessage ?: "Embedded photo picker is unavailable."),
                        ),
                    )
                }
            }
        } else {
            createUnsupportedView(context).also {
                channel.invokeMethod(
                    "unsupported",
                    mapOf(
                        "code" to "unsupported_android_version",
                        "message" to "Embedded photo picker requires Android 14 with U Extension 15 or newer.",
                    ),
                )
            }
        }
    }

    private fun createEmbeddedPickerView(context: Context): EmbeddedPhotoPickerView {
        val pickerView = EmbeddedPhotoPickerView(context)
        val stateListener = object : EmbeddedPhotoPickerView.EmbeddedPhotoPickerStateChangeListener {
            override fun onSessionOpened(newSession: EmbeddedPhotoPickerSession) {
                channel.invokeMethod("sessionOpened", null)
            }

            override fun onUriPermissionGranted(uris: List<Uri>) {
                channel.invokeMethod(
                    "uriPermissionGranted",
                    uris.map {
                        MediaItem.fromUri(
                            resolver = context.contentResolver,
                            uri = it,
                            isTemporary = false,
                        ).toMap()
                    },
                )
            }

            override fun onUriPermissionRevoked(uris: List<Uri>) {
                channel.invokeMethod(
                    "uriPermissionRevoked",
                    uris.map {
                        MediaItem.fromUri(
                            resolver = context.contentResolver,
                            uri = it,
                            isTemporary = false,
                        ).toMap()
                    },
                )
            }

            override fun onSelectionComplete() {
                channel.invokeMethod("selectionComplete", null)
            }

            override fun onSessionError(throwable: Throwable) {
                channel.invokeMethod(
                    "sessionError",
                    mapOf(
                        "code" to "session_error",
                        "message" to (throwable.localizedMessage ?: "Embedded photo picker session failed."),
                    ),
                )
            }
        }

        pickerView.addEmbeddedPhotoPickerStateChangeListener(stateListener)
        pickerView.setEmbeddedPhotoPickerFeatureInfo(options.toFeatureInfo())
        embeddedPickerView = pickerView
        listener = stateListener
        return pickerView
    }

    private fun createUnsupportedView(context: Context): View {
        return FrameLayout(context).apply {
            addView(
                TextView(context).apply {
                    text = "Embedded photo picker is not available on this Android version."
                    gravity = Gravity.CENTER
                },
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
        }
    }

    private fun PickerOptions.toFeatureInfo(): EmbeddedPhotoPickerFeatureInfo {
        return EmbeddedPhotoPickerFeatureInfo.Builder().apply {
            if (mimeTypes.isNotEmpty()) {
                setMimeTypes(mimeTypes)
            }
            if (maxSelectionLimit > 0) {
                setMaxSelectionLimit(maxSelectionLimit.coerceAtMost(MediaStore.getPickImagesMaxLimit()))
            }
            if (preselectedUris.isNotEmpty()) {
                setPreSelectedUris(preselectedUris)
            }
            accentColorArgb?.let { setAccentColor(it) }
            setOrderedSelection(orderedSelection)
            setThemeNightMode(
                when (theme) {
                    "light" -> Configuration.UI_MODE_NIGHT_NO
                    "dark" -> Configuration.UI_MODE_NIGHT_YES
                    else -> Configuration.UI_MODE_NIGHT_UNDEFINED
                },
            )
        }.build()
    }

    override fun getView(): View = contentView

    override fun dispose() {
        val pickerView = embeddedPickerView
        val stateListener = listener
        if (pickerView != null && stateListener != null) {
            pickerView.removeEmbeddedPhotoPickerStateChangeListener(stateListener)
        }
        channel.setMethodCallHandler(null)
    }
}
