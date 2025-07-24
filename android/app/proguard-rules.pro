# Flutter SVG 관련 ProGuard 규칙
# android/app/proguard-rules.pro

# Flutter 관련 클래스 보호
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SVG 관련 클래스 보호
-keep class com.caverock.androidsvg.** { *; }
-keep class androidx.webkit.** { *; }
-keep class androidx.browser.** { *; }

# 네트워크 관련 클래스 보호
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }

# WebView 관련 클래스 보호
-keep class android.webkit.** { *; }
-keepclassmembers class android.webkit.** { *; }

# 일반적인 Android 클래스 보호
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }

# 디버깅을 위한 라인 넘버 보존
-keepattributes SourceFile,LineNumberTable

# 난독화 최적화 방지 (SVG 로딩 문제 해결)
-dontoptimize
-dontobfuscate