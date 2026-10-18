package com.example.flutter_aircon_remote

import android.content.Context
import android.hardware.ConsumerIrManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class IrChannelHandler(context: Context) : MethodChannel.MethodCallHandler {
    companion object { const val CHANNEL = "com.example.flutter_aircon_remote/ir" }
    private val manager = context.getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }
    private fun hasEmitter(): Boolean = try { manager?.hasIrEmitter() == true } catch (_: Exception) { false }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasIrEmitter" -> result.success(hasEmitter())
            "getCarrierFrequencies" -> {
                val ranges = try {
                    if (hasEmitter()) manager?.carrierFrequencies?.map { mapOf("min" to it.minFrequency, "max" to it.maxFrequency) } else emptyList()
                } catch (_: Exception) { emptyList<Map<String, Int>>() }
                result.success(ranges ?: emptyList<Map<String, Int>>())
            }
            "transmit" -> transmit(call, result)
            else -> result.notImplemented()
        }
    }
    private fun transmit(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val carrier = args?.get("carrierHz") as? Int
        val values = args?.get("pattern") as? List<*>
        if (carrier == null || carrier <= 0 || values.isNullOrEmpty() || values.any { it !is Int || it <= 0 }) {
            result.error("INVALID_ARGUMENT", "Invalid frequency or pattern", null)
            return
        }
        val pattern = values.map { it as Int }.toIntArray()
        if (pattern.size > 1000 || pattern.sumOf { it.toLong() } >= 2_000_000L) {
            result.error("PATTERN_TOO_LONG", "Pattern exceeds platform limits", null)
            return
        }
        executor.execute {
            fun fail(code: String, message: String?) { main.post {
                try { result.error(code, message, null) } catch (_: Exception) { /* Engine detached. */ }
            } }
            try {
                val service = manager
                if (service == null || !service.hasIrEmitter()) {
                    fail("NO_IR_EMITTER", "No IR emitter")
                } else {
                    val ranges = service.carrierFrequencies
                    if (!ranges.isNullOrEmpty() && ranges.none { carrier in it.minFrequency..it.maxFrequency }) {
                        fail("UNSUPPORTED_FREQUENCY", "Unsupported carrier frequency")
                    } else {
                        service.transmit(carrier, pattern)
                        main.post {
                            try { result.success(null) } catch (_: Exception) { /* Engine detached. */ }
                        }
                    }
                }
            } catch (e: SecurityException) { fail("PERMISSION_DENIED", e.message) }
              catch (e: Exception) { fail("TRANSMIT_FAILED", e.toString()) }
        }
    }
    fun dispose() {
        channel?.setMethodCallHandler(null)
        executor.shutdownNow()
    }
}
