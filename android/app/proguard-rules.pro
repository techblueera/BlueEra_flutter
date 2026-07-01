# Keep Razorpay classes
-keepattributes *Annotation*
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

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

# Firebase Core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep Parcelize classes and metadata
-keep class kotlinx.parcelize.** { *; }

# Keep all Giphy SDK models (they use Parcelize)
-keep class com.giphy.sdk.** { *; }


# --- Jitsi Meet SDK ---
-keep class org.jitsi.meet.** { *; }
-dontwarn org.jitsi.meet.**

# React Native (Jitsi SDK uses it internally)
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**


-keep class org.jitsi.** { *; }
-dontwarn org.webrtc.**

# Meta Audience Network (Facebook Ads) SDK
# The SDK references Facebook's compile-only `infer` annotations
# (com.facebook.infer.annotation.Nullsafe) that aren't on the runtime
# classpath — silence R8's "Missing class" errors and keep the ad classes.
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**
-keep class com.facebook.infer.** { *; }
-dontwarn com.facebook.infer.annotation.**



