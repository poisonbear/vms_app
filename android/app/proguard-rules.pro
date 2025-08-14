# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# ==================== Flutter 관련 규칙 ====================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter 엔진 관련
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# ==================== Firebase 관련 규칙 (업데이트됨) ====================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth 관련
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Firebase Messaging 관련
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-dontwarn com.google.firebase.messaging.**

# Firebase Firestore 관련
-keep class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Firebase Analytics 관련
-keep class com.google.firebase.analytics.** { *; }
-dontwarn com.google.firebase.analytics.**

# ==================== Firebase Crashlytics 관련 규칙 (수정됨) ====================
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**
# 구버전 Crashlytics 규칙 제거 (com.crashlytics는 더 이상 사용되지 않음)

# ==================== 네트워크 관련 규칙 ====================
# Dio/OkHttp 관련 규칙 (업데이트됨)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Retrofit (만약 사용한다면)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# ==================== JSON 직렬화 관련 규칙 ====================
# Gson 관련 규칙 (개선됨)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Jackson (만약 사용한다면)
-keep @com.fasterxml.jackson.annotation.JsonIgnoreProperties class * { *; }
-keep class com.fasterxml.jackson.** { *; }

# ==================== 앱별 모델 클래스 보호 ====================
-keep class kdn.vms.app.** { *; }
-keep class ** extends java.io.Serializable { *; }

# 데이터 모델 클래스들 (추가 보호)
-keep public class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==================== Android 컴포넌트 관련 ====================
# AndroidX 관련
-keep class androidx.** { *; }
-dontwarn androidx.**

# 위치 서비스 관련 (Geolocator)
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# 권한 처리 관련 (Permission Handler)
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ==================== 일반적인 Android 규칙 ====================
# 네이티브 메서드 보호
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum 클래스 보호
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# WebView JavaScript 인터페이스
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 리플렉션 관련
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ==================== 최적화 설정 ====================
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-allowaccessmodification
-repackageclasses ''

# 최적화 제외 (안정성을 위해)
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# ==================== 추가 보안 및 안정성 규칙 ====================
# 암호화 관련 (crypto 패키지)
-keep class javax.crypto.** { *; }
-dontwarn javax.crypto.**

# 디버그 정보 유지 (Crashlytics를 위해)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 워커 스레드 관련 (WorkManager)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ==================== 알림 관련 ====================
# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ==================== 지도 관련 (만약 사용한다면) ====================
# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

# Flutter Map
-keep class org.maplibre.** { *; }
-dontwarn org.maplibre.**

# ==================== 로깅 관련 ====================
# Logger 패키지
-keep class logger.** { *; }
-dontwarn logger.**

# ==================== Kotlin 관련 ====================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}