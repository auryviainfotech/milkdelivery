# Flutter ProGuard Rules
# Keep Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase/Realtime classes
-keep class io.supabase.** { *; }
-keep class com.google.crypto.tink.** { *; }

# Keep Mobile Scanner (QR) classes
-keep class com.google.mlkit.** { *; }

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
