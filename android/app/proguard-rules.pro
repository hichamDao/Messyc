# Garder toutes les classes de TensorFlow Lite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Garder les classes Kotlin (utile pour éviter des erreurs si tu utilises des libs Kotlin)
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Garder les classes Flutter nécessaires
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Garder les classes utilisées par les plugins Flutter
-keep class com.google.** { *; }
-dontwarn com.google.**

# Garder les classes AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**
