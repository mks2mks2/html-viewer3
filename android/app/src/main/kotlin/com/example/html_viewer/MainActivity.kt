package com.example.html_viewer

import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onStart() {
        super.onStart()
        WebView.setWebContentsDebuggingEnabled(false)
        val webView = WebView(this)
        webView.settings.allowFileAccess = true
        webView.settings.allowContentAccess = true
        webView.settings.mediaPlaybackRequiresUserGesture = false
    }
}
