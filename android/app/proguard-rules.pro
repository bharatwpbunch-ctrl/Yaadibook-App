# Yaadibook R8 / ProGuard keep rules for Play Store release builds

# Google Play Billing Library
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Firebase Messaging / Core
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Flutter & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn com.google.android.play.core.**

# SQLite / Drift JNI symbols
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

