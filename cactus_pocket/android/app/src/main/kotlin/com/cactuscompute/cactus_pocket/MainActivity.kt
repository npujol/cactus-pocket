package com.cactuscompute.cactus_pocket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        val model = call.argument<ByteArray>("model")
                        if (model == null) result.error("invalid_model", "Model bytes are missing", null)
                        else inferenceExecutor.execute {
                            try {
                                val error = native.loadModel(model)
                                runOnUiThread {
                                    if (error == null) result.success(true)
                                    else result.error("model_load_failed", error, null)
                                }
                            } catch (error: Throwable) {
                                runOnUiThread { result.error("model_load_failed", error.message, null) }
                            }
                        }
                    }
                    "isModelReady" -> inferenceExecutor.execute {
                        val ready = native.isModelReady()
                        runOnUiThread { result.success(ready) }
                    }
                    "describe" -> {
                        val rgb = call.argument<ByteArray>("rgb")
                        val width = call.argument<Int>("width")
                        val height = call.argument<Int>("height")
                        if (rgb == null || width == null || height == null) {
                            result.error("invalid_image", "Packed RGB and image dimensions are required", null)
                        } else {
                            val options = call.argument<String>("options") ?: "{}"
                            val language = call.argument<String>("language") ?: "en"
                            val keywords = call.argument<String>("keywords") ?: ""
                            inferenceExecutor.execute {
                                try {
                                    val json = native.describe(rgb, width, height, options, language, keywords)
                                    runOnUiThread { result.success(json) }
                                } catch (error: Throwable) {
                                    runOnUiThread { result.error("inference_failed", error.message, null) }
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "com.cactuscompute.cactus_pocket/mirage"
        private val inferenceExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
        private val native by lazy { CactusNative() }
    }
}
