# Razorpay Flutter SDK (release minify when enabled).
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Firebase — R8 must not strip component registrars (Crashlytics / Messaging).
# Without this, Firebase.initializeApp fails with:
# "FirebaseCrashlytics component is not present" (often via Razorpay on Android).
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class io.flutter.plugins.firebase.** { *; }
