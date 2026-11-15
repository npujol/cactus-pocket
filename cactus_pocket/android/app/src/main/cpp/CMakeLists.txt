cmake_minimum_required(VERSION 3.22.1)
project(cactus_pocket_native LANGUAGES C CXX)

add_library(cactus STATIC IMPORTED)
set_target_properties(cactus PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/../native-libs/arm64-v8a/libcactus.a"
)

add_library(cactus_jni SHARED cactus_jni.cpp)
target_include_directories(cactus_jni PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_compile_features(cactus_jni PRIVATE cxx_std_17)
target_compile_options(cactus_jni PRIVATE -Wall -Wextra -Werror=return-type)
target_link_libraries(cactus_jni PRIVATE cactus android log)
