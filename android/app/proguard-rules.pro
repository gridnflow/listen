# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# just_audio / audio_service
-keep class com.ryanheise.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.ryanheise.**
-dontwarn androidx.media3.**

# ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Drift / SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }
-dontwarn org.sqlite.**

# on_audio_query
-keep class com.lucasjosino.on_audio_query.** { *; }
-dontwarn com.lucasjosino.**

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# cached_network_image / dio
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**

# Kotlin
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn kotlin.**

# Keep all annotations and signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}
