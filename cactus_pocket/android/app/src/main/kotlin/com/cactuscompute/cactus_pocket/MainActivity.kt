package com.cactuscompute.cactus_pocket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleCall)
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> loadModel(call, result)
            "isModelReady" -> queryModelState(result)
            "describe" -> describe(call, result)
            else -> result.notImplemented()
        }
    }

    private fun loadModel(call: MethodCall, result: MethodChannel.Result) {
        val model = call.argument<ByteArray>("model")
        if (model == null) {
            result.error("invalid_model", "Model bytes are missing", null)
            return
        }
        inferenceExecutor.execute { loadModelOnWorker(model, result) }
    }

    private fun loadModelOnWorker(model: ByteArray, result: MethodChannel.Result) {
        try {
            val error = native.loadModel(model)
            runOnUiThread {
                if (error == null) {
                    result.success(true)
                } else {
                    result.error("model_load_failed", error, null)
                }
            }
        } catch (error: Throwable) {
            reportError(result, "model_load_failed", error, "Model loading failed")
        }
    }

    private fun queryModelState(result: MethodChannel.Result) {
        inferenceExecutor.execute {
            try {
                val ready = native.isModelReady()
                runOnUiThread { result.success(ready) }
            } catch (error: Throwable) {
                reportError(result, "native_failure", error, "Unable to query model state")
            }
        }
    }

    private fun describe(call: MethodCall, result: MethodChannel.Result) {
        val rgb = call.argument<ByteArray>("rgb")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        ImageInputLimits.invokeForValidImage(
            rgb = rgb,
            width = width,
            height = height,
            onInvalid = {
                result.error(
                    "invalid_image",
                    "RGB data must match positive image dimensions no larger than 2048 pixels per side or 4 megapixels",
                    null,
                )
            },
            onValid = { validRgb, validWidth, validHeight ->
                val options = call.argument<String>("options") ?: "{}"
                val language = call.argument<String>("language") ?: "en"
                val keywords = call.argument<String>("keywords") ?: ""
                inferenceExecutor.execute {
                    describeOnWorker(
                        validRgb,
                        validWidth,
                        validHeight,
                        options,
                        language,
                        keywords,
                        result,
                    )
                }
            },
        )
    }

    private fun describeOnWorker(
        rgb: ByteArray,
        width: Int,
        height: Int,
        options: String,
        language: String,
        keywords: String,
        result: MethodChannel.Result,
    ) {
        try {
            val json = native.describe(rgb, width, height, options, language, keywords)
            runOnUiThread { result.success(json) }
        } catch (error: Throwable) {
            reportError(result, "inference_failed", error, "Image inference failed")
        }
    }

    private fun reportError(
        result: MethodChannel.Result,
        code: String,
        error: Throwable,
        fallback: String,
    ) {
        runOnUiThread { result.error(code, error.message ?: fallback, null) }
    }

    companion object {
        private const val CHANNEL = "com.cactuscompute.cactus_pocket/mirage"
        private val inferenceExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
        private val native by lazy { CactusNative() }
    }
}
