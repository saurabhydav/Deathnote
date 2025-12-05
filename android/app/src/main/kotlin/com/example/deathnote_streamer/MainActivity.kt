package com.example.deathnote_streamer

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "deathnote_live/stream"
    private val REQUEST_CODE = 100
    private var pendingResult: MethodChannel.Result? = null
    private var streamUrl: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startStream" -> {
                    streamUrl = call.argument<String>("url") ?: ""
                    pendingResult = result
                    requestMediaProjection()
                }
                "stopStream" -> {
                    val intent = Intent(this, StreamService::class.java)
                    intent.action = "STOP"
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestMediaProjection() {
        val mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            val intent = Intent(this, StreamService::class.java).apply {
                action = "START"
                putExtra("code", resultCode)
                putExtra("data", data)
                putExtra("endpoint", streamUrl)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            pendingResult?.success(true)
        } else {
            pendingResult?.error("PERMISSION_DENIED", "Screen capture permission denied", null)
        }
    }
}