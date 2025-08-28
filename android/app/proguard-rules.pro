# 모든 Flutter 클래스 보호
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core 완전 보호
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Firebase & Google Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# 앱 패키지
-keep class kdn.vms.app.** { *; }

# 모든 모델 클래스 보호
-keep class **.model.** { *; }
-keep class **.models.** { *; }
-keepclassmembers class **.model.** { *; }
-keepclassmembers class **.models.** { *; }

# Serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 네트워크 라이브러리
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Kotlin
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# 경고 무시
-ignorewarnings
