#!/usr/bin/env bash
set -euo pipefail

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

"${CXX:-c++}" \
  -std=c++17 \
  -Wall \
  -Wextra \
  -Werror \
  -I"$app_root/android/app/src/main/cpp" \
  "$app_root/android/app/src/test/cpp/image_input_limits_test.cpp" \
  -o "$test_dir/image_input_limits_test"
"$test_dir/image_input_limits_test"
