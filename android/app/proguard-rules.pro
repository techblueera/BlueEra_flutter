# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

-keepattributes *Annotation*


# Keep Gson classes
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep AutoValue Gson TypeAdapter
-keep class com.ryanharter.auto.value.gson.** { *; }
-dontwarn com.ryanharter.auto.value.gson.**

# Keep Mappls SDK models/adapters
-keep class com.mappls.sdk.** { *; }
-dontwarn com.mappls.sdk.**

# Keep ffmpeg-kit classes if you’re using ffmpeg_kit_flutter_min
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Keep Flutter JNI stuff
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

