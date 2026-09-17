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

# Keep Flutter JNI stuff.
#
# The whole io.flutter tree, not just io.flutter.embedding. The embedding
# arrives as a plain JAR (flutter_embedding_release-*.jar), and a JAR cannot
# carry consumer ProGuard rules the way an AAR can — verified: it ships none.
# So nothing keeps any of it except what is written here, while
# android.enableR8.fullMode=true and proguard-android-optimize.txt let R8
# shrink, merge and access-modify freely.
#
# io.flutter.view was outside the old rule, and that is where
# NoClassDefFoundError "Failed resolution of: Lio/flutter/view/a;" came from —
# AccessibilityBridge (io.flutter.view.n) failing to resolve a sibling in its
# own package while FlutterView attached to the engine, i.e. on every launch
# for the affected builds. io.flutter.plugin and io.flutter.util are reached
# over JNI and by plugin reflection and are equally unprotected.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

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



