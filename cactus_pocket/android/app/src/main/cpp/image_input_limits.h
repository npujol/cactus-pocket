#pragma once

#include <cstdint>

namespace cactus_pocket {
inline constexpr std::int64_t kMaximumImageSide = 2048;
inline constexpr std::int64_t kMaximumImagePixels = 4LL * 1024 * 1024;
inline constexpr std::int64_t kRgbChannels = 3;

inline bool checkedRgbByteCount(
    std::int64_t width,
    std::int64_t height,
    std::int64_t actualLength,
    std::int64_t maxArrayLength,
    std::int64_t* byteCount) {
  if (byteCount == nullptr || width <= 0 || height <= 0 || actualLength < 0 ||
      maxArrayLength < 0 || width > kMaximumImageSide || height > kMaximumImageSide) {
    return false;
  }
  if (width > kMaximumImagePixels / height) return false;

  const std::int64_t pixelCount = width * height;
  if (pixelCount > kMaximumImagePixels ||
      pixelCount > maxArrayLength / kRgbChannels) {
    return false;
  }

  *byteCount = pixelCount * kRgbChannels;
  return *byteCount <= maxArrayLength && *byteCount == actualLength;
}

template <typename Action>
inline bool invokeForValidRgb(
    std::int64_t width,
    std::int64_t height,
    std::int64_t actualLength,
    std::int64_t maxArrayLength,
    Action action) {
  std::int64_t byteCount = 0;
  if (!checkedRgbByteCount(width, height, actualLength, maxArrayLength, &byteCount)) {
    return false;
  }
  action(byteCount);
  return true;
}
}  // namespace cactus_pocket
