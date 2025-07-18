
package com.example.ronda_vigilante

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
