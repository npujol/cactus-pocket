LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := cactus
LOCAL_SRC_FILES := ../native-libs/arm64-v8a/libcactus.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := cactus_jni
LOCAL_SRC_FILES := ../cpp/cactus_jni.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../cpp
LOCAL_CPPFLAGS := -std=c++17 -Wall -Wextra
LOCAL_LDLIBS := -llog -landroid -lz -ldl -lm
LOCAL_STATIC_LIBRARIES := cactus
include $(BUILD_SHARED_LIBRARY)
