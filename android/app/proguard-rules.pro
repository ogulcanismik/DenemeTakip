# WorkManager is initialized by google_mobile_ads before the first frame.
# R8 must keep the Room implementation WorkManager instantiates by reflection.
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**
