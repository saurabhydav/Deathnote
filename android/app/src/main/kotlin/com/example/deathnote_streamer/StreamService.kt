package com.example.deathnote_streamer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.pedro.rtplibrary.rtmp.RtmpDisplay
import com.pedro.rtmp.utils.ConnectCheckerRtmp

class StreamService : Service(), ConnectCheckerRtmp {

    private var rtmpDisplay: RtmpDisplay? = null
    private val CHANNEL_ID = "StreamingChannel"
    private val NOTIFICATION_ID = 12345

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // Initialize the library
        rtmpDisplay = RtmpDisplay(baseContext, true, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                val resultCode = intent.getIntExtra("code", -1)
                val resultData = intent.getParcelableExtra<Intent>("data")
                val endpoint = intent.getStringExtra("endpoint")

                val notification = createNotification()
                startForeground(NOTIFICATION_ID, notification)

                if (resultCode != -1 && resultData != null && endpoint != null) {
                    startStream(resultCode, resultData, endpoint)
                }
            }
            "STOP" -> {
                stopStream()
                stopForeground(true)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startStream(code: Int, data: Intent, endpoint: String) {
        if (rtmpDisplay?.isStreaming == false) {
            // Setup 720p (1280x720), 30fps, 4Mbps bitrate
            // This is safer than 1080p for mobile data
            rtmpDisplay?.setIntentResult(code, data)
            if (rtmpDisplay?.prepareAudio() == true && 
                rtmpDisplay?.prepareVideo(1280, 720, 30, 4000 * 1024, 320, 0) == true) {
                rtmpDisplay?.startStream(endpoint)
            } else {
                Log.e("StreamService", "Error preparing stream, check resolution/bitrate")
            }
        }
    }

    private fun stopStream() {
        if (rtmpDisplay?.isStreaming == true) {
            rtmpDisplay?.stopStream()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Live Stream", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DeathNote Live")
            .setContentText("Ritual in progress (Streaming)...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (rtmpDisplay?.isStreaming == true) {
            rtmpDisplay?.stopStream()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --- ConnectCheckerRtmp Interface Implementation ---
    
    override fun onConnectionStartedRtmp(rtmpUrl: String) {
        Log.d("StreamService", "Connection Started: $rtmpUrl")
    }

    override fun onConnectionSuccessRtmp() { 
        Log.d("StreamService", "Connected") 
    }
    
    override fun onConnectionFailedRtmp(reason: String) { 
        Log.e("StreamService", "Failed: $reason") 
    }
    
    override fun onNewBitrateRtmp(bitrate: Long) {}
    
    override fun onDisconnectRtmp() { 
        Log.d("StreamService", "Disconnected") 
    }
    
    override fun onAuthErrorRtmp() {}
    
    override fun onAuthSuccessRtmp() {}
}