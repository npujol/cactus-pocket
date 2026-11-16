package com.cactuscompute.cactus_pocket

internal object ImageInputLimits {
    const val MAX_IMAGE_SIDE = 2048
    const val MAX_IMAGE_PIXELS = 4 * 1024 * 1024
    const val RGB_CHANNELS = 3

    fun expectedRgbByteCount(width: Int, height: Int): Long? {
        val positiveDimensions = width > 0 && height > 0
        val withinSideLimits = width <= MAX_IMAGE_SIDE && height <= MAX_IMAGE_SIDE
        val widthLong = width.toLong()
        val heightLong = height.toLong()
        val pixelLimit = MAX_IMAGE_PIXELS.toLong()
        val withinPixelLimit =
            positiveDimensions && withinSideLimits && widthLong <= pixelLimit / heightLong
        val pixelCount = if (withinPixelLimit) widthLong * heightLong else 0L
        val byteCount = pixelCount * RGB_CHANNELS
        val maxByteArrayLength = Int.MAX_VALUE.toLong()
        return byteCount.takeIf {
            pixelCount > 0 && pixelCount <= pixelLimit && it <= maxByteArrayLength
        }
    }

    fun isValidImage(rgb: ByteArray?, width: Int?, height: Int?): Boolean {
        val expectedBytes = expectedRgbByteCount(width ?: 0, height ?: 0)
        return rgb != null && expectedBytes != null && expectedBytes == rgb.size.toLong()
    }

    fun <T> invokeForValidImage(
        rgb: ByteArray?,
        width: Int?,
        height: Int?,
        onInvalid: () -> T,
        onValid: (ByteArray, Int, Int) -> T,
    ): T {
        if (!isValidImage(rgb, width, height)) return onInvalid()
        return onValid(checkNotNull(rgb), checkNotNull(width), checkNotNull(height))
    }
}
