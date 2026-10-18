package com.example.flutter_aircon_remote

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var handler: IrChannelHandler? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handler = IrChannelHandler(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }
    override fun onDestroy() {
        handler?.dispose()
        super.onDestroy()
    }
}
