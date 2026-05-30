# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# AppsFlyer
-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

# WebView JS interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
