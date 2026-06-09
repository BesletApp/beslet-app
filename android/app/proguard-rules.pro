# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson TypeToken — keeps anonymous TypeToken subclasses from being obfuscated
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * extends com.google.gson.reflect.TypeToken { *; }

# Keep generic type metadata needed for Gson deserialization
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes *Annotation*

# Keep ScheduledNotification model class
-keep class com.dexterous.flutterlocalnotifications.models.ScheduledNotification { *; }
