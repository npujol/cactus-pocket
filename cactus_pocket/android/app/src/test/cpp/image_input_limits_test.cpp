#include "image_input_limits.h"

#include <cassert>
#include <cstdint>
#include <limits>

int main() {
  std::int64_t byteCount = -1;
  constexpr std::int64_t maxJniArrayLength = std::numeric_limits<std::int32_t>::max();

  assert(cactus_pocket::checkedRgbByteCount(1, 1, 3, maxJniArrayLength, &byteCount));
  assert(byteCount == 3);
  assert(cactus_pocket::checkedRgbByteCount(
      2048, 2048, 2048LL * 2048 * 3, maxJniArrayLength, &byteCount));
  assert(byteCount == 2048LL * 2048 * 3);

  assert(!cactus_pocket::checkedRgbByteCount(0, 1, 0, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(-1, 1, 0, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(1, -1, 0, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(2049, 1, 6147, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(2048, 2049, 2048LL * 2049 * 3,
                                             maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(
      std::numeric_limits<std::int64_t>::max(), 2, 0, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(1, 1, 2, maxJniArrayLength, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(
      2048, 2048, 2048LL * 2048 * 3, 1024, &byteCount));
  assert(!cactus_pocket::checkedRgbByteCount(1, 1, 3, maxJniArrayLength, nullptr));

  int nativeCalls = 0;
  const auto rejectsBeforeNative = [&nativeCalls, maxJniArrayLength](
                                      std::int64_t width,
                                      std::int64_t height,
                                      std::int64_t actualLength) {
    const bool accepted = cactus_pocket::invokeForValidRgb(
        width, height, actualLength, maxJniArrayLength,
        [&nativeCalls](std::int64_t) { ++nativeCalls; });
    assert(!accepted);
    assert(nativeCalls == 0);
  };
  rejectsBeforeNative(0, 1, 0);
  rejectsBeforeNative(-1, 1, 0);
  rejectsBeforeNative(2049, 1, 2049LL * 3);
  rejectsBeforeNative(std::numeric_limits<std::int64_t>::max(), 2, 0);
  rejectsBeforeNative(1, 1, 2);

  const bool accepted = cactus_pocket::invokeForValidRgb(
      2048, 2048, 2048LL * 2048 * 3, maxJniArrayLength,
      [&nativeCalls](std::int64_t bytes) {
        assert(bytes == 2048LL * 2048 * 3);
        ++nativeCalls;
      });
  assert(accepted);
  assert(nativeCalls == 1);
}
