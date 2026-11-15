#include <jni.h>
#include <android/log.h>

#include <cactus.h>

#include <mutex>
#include <string>
#include <vector>

namespace {
constexpr const char* kTag = "CactusMirage";
constexpr jint kOutputCapacity = 16 * 1024 * 1024;
std::mutex gEngineMutex;
bool gModelReady = false;

std::string lastError() {
  const char* error = cactus_last_error();
  return error == nullptr || error[0] == '\0' ? "Cactus runtime returned an unspecified error" : error;
}

jstring toJavaString(JNIEnv* env, const std::string& value) {
  return env->NewStringUTF(value.c_str());
}

void throwJavaException(JNIEnv* env, const char* className, const std::string& message) {
  jclass exceptionClass = env->FindClass(className);
  if (exceptionClass == nullptr) return;
  env->ThrowNew(exceptionClass, message.c_str());
  env->DeleteLocalRef(exceptionClass);
}
}  // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_cactuscompute_cactus_1pocket_CactusNative_loadModel(
    JNIEnv* env, jobject /* thiz */, jbyteArray modelBytes) {
  if (modelBytes == nullptr) return toJavaString(env, "Model bytes are missing");
  const jsize size = env->GetArrayLength(modelBytes);
  if (size <= 0) return toJavaString(env, "Model file is empty");

  std::vector<unsigned char> model(static_cast<size_t>(size));
  env->GetByteArrayRegion(modelBytes, 0, size, reinterpret_cast<jbyte*>(model.data()));
  if (env->ExceptionCheck()) return nullptr;

  std::lock_guard<std::mutex> lock(gEngineMutex);
  const int result = cactus_load(model.data(), static_cast<unsigned long long>(model.size()));
  if (result < 0) {
    gModelReady = false;
    const auto error = lastError();
    __android_log_print(ANDROID_LOG_ERROR, kTag, "cactus_load failed: %s", error.c_str());
    return toJavaString(env, error);
  }
  if ((cactus_models() & CACTUS_VISION) == 0) {
    gModelReady = false;
    return toJavaString(env, "Loaded model does not include Mirage vision capability");
  }
  gModelReady = true;
  return nullptr;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_cactuscompute_cactus_1pocket_CactusNative_isModelReady(
    JNIEnv* /* env */, jobject /* thiz */) {
  std::lock_guard<std::mutex> lock(gEngineMutex);
  return gModelReady ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_cactuscompute_cactus_1pocket_CactusNative_describe(
    JNIEnv* env, jobject /* thiz */, jbyteArray rgbBytes, jint width, jint height,
    jstring optionsValue, jstring languageValue, jstring keywordsValue) {
  if (rgbBytes == nullptr || width <= 0 || height <= 0) {
    throwJavaException(env, "java/lang/IllegalArgumentException",
                       "Image RGB data and positive dimensions are required");
    return nullptr;
  }
  const jlong expected = static_cast<jlong>(width) * height * 3;
  if (expected <= 0 || expected != env->GetArrayLength(rgbBytes)) {
    throwJavaException(env, "java/lang/IllegalArgumentException",
                       "Packed RGB byte count must equal width * height * 3");
    return nullptr;
  }

  auto readString = [env](jstring value, const char* fallback) -> std::string {
    if (value == nullptr) return fallback;
    const char* chars = env->GetStringUTFChars(value, nullptr);
    if (chars == nullptr) return {};
    std::string result(chars);
    env->ReleaseStringUTFChars(value, chars);
    return result;
  };
  const std::string options = readString(optionsValue, "{}");
  const std::string language = readString(languageValue, "en");
  const std::string keywords = readString(keywordsValue, "");
  if (env->ExceptionCheck()) return nullptr;

  std::vector<unsigned char> rgb(static_cast<size_t>(expected));
  env->GetByteArrayRegion(rgbBytes, 0, static_cast<jsize>(expected), reinterpret_cast<jbyte*>(rgb.data()));
  if (env->ExceptionCheck()) return nullptr;

  std::vector<char> output(kOutputCapacity, '\0');
  std::lock_guard<std::mutex> lock(gEngineMutex);
  if (!gModelReady) {
    throwJavaException(env, "java/lang/IllegalStateException",
                       "Mirage model is not loaded; download and load it first");
    return nullptr;
  }

  const int result = cactus_describe(rgb.data(), width, height, options.c_str(), language.c_str(),
                                     keywords.c_str(), output.data(), static_cast<int>(output.size()));
  if (result < 0) {
    const auto error = lastError();
    __android_log_print(ANDROID_LOG_ERROR, kTag, "cactus_describe failed: %s", error.c_str());
    throwJavaException(env, "java/lang/IllegalStateException", error);
    return nullptr;
  }
  return toJavaString(env, std::string(output.data()));
}
