package com.cactuscompute.cactus_pocket

/** JNI bindings to the pinned Cactus 4.1.1 runtime. Calls are executed by [MirageRepository] off the UI thread. */
internal class CactusNative {
    external fun loadModel(modelBytes: ByteArray): String?

    external fun isModelReady(): Boolean

    external fun describe(
        rgb: ByteArray,
        width: Int,
        height: Int,
        options: String,
        language: String,
        keywords: String,
    ): String

    companion object {
        init {
            System.loadLibrary("cactus_jni")
        }
    }
}
