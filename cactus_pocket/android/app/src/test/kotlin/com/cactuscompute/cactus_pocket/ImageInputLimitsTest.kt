package com.cactuscompute.cactus_pocket

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ImageInputLimitsTest {
    @Test
    fun acceptsMatchingRgbBufferAtMaximumDimensions() {
        val expectedBytes = 2048L * 2048L * ImageInputLimits.RGB_CHANNELS

        assertEquals(expectedBytes, ImageInputLimits.expectedRgbByteCount(2048, 2048))
        assertTrue(ImageInputLimits.isValidImage(ByteArray(expectedBytes.toInt()), 2048, 2048))
    }

    @Test
    fun rejectsNonPositiveAndOverLimitDimensions() {
        assertNull(ImageInputLimits.expectedRgbByteCount(0, 1))
        assertNull(ImageInputLimits.expectedRgbByteCount(1, 0))
        assertNull(ImageInputLimits.expectedRgbByteCount(-1, 1))
        assertNull(ImageInputLimits.expectedRgbByteCount(1, -1))
        assertNull(ImageInputLimits.expectedRgbByteCount(2049, 1))
        assertNull(ImageInputLimits.expectedRgbByteCount(1, 2049))
        assertNull(ImageInputLimits.expectedRgbByteCount(Int.MAX_VALUE, Int.MAX_VALUE))
    }

    @Test
    fun rejectsMissingAndMismatchedBuffers() {
        assertFalse(ImageInputLimits.isValidImage(null, 1, 1))
        assertFalse(ImageInputLimits.isValidImage(byteArrayOf(1, 2), 1, 1))
        assertFalse(ImageInputLimits.isValidImage(byteArrayOf(1, 2, 3), null, 1))
        assertFalse(ImageInputLimits.isValidImage(byteArrayOf(1, 2, 3), 1, null))
    }

    @Test
    fun invalidInputsNeverInvokeTheNativeCall() {
        val invalidInputs = listOf(
            Triple(byteArrayOf(1, 2, 3), 0, 1),
            Triple(byteArrayOf(1, 2, 3), -1, 1),
            Triple(byteArrayOf(1, 2, 3), 2049, 1),
            Triple(byteArrayOf(1, 2, 3), Int.MAX_VALUE, Int.MAX_VALUE),
            Triple(byteArrayOf(1, 2), 1, 1),
        )

        invalidInputs.forEach { (rgb, width, height) ->
            var nativeCalls = 0
            val accepted = ImageInputLimits.invokeForValidImage(
                rgb,
                width,
                height,
                onInvalid = { false },
                onValid = { _, _, _ ->
                    nativeCalls++
                    true
                },
            )

            assertFalse(accepted)
            assertEquals(0, nativeCalls)
        }
    }

    @Test
    fun validBoundaryInputInvokesTheNativeCallOnce() {
        val rgb = ByteArray(2048 * 2048 * ImageInputLimits.RGB_CHANNELS)
        var nativeCalls = 0

        val accepted = ImageInputLimits.invokeForValidImage(
            rgb,
            2048,
            2048,
            onInvalid = { false },
            onValid = { _, _, _ ->
                nativeCalls++
                true
            },
        )

        assertTrue(accepted)
        assertEquals(1, nativeCalls)
    }
}
