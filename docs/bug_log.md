# Bug & Error Log

All errors and bugs encountered during development, with root causes and fixes.

---

## [BUG-001] App crash on launch — ClassNotFoundException for MainActivity

**Date:** 2025-04  
**Symptom:** App crashed immediately on launch with `ClassNotFoundException: com.gridnflow.listen.MainActivity`  
**Root Cause:** `MainActivity.kt` was located at the wrong package path (`com/listen/listen/`) while `applicationId` was `com.gridnflow.listen`. Android couldn't find the class.  
**Fix:** Created new `MainActivity.kt` at `android/app/src/main/kotlin/com/gridnflow/listen/MainActivity.kt` and deleted the old file.

---

## [BUG-002] App crash — IllegalStateException: wrong Activity class for FlutterEngine

**Date:** 2025-04  
**Symptom:** App launched but crashed with `IllegalStateException: Tried to attach to a FlutterEngine with a non-FlutterActivity`.  
**Root Cause:** `MainActivity` extended `FlutterActivity` instead of `AudioServiceActivity`, which is required by the `audio_service` package.  
**Fix:** Changed `class MainActivity : FlutterActivity()` → `class MainActivity : AudioServiceActivity()`.

---

## [BUG-003] App crash — Unable to bind to AudioService

**Date:** 2025-04  
**Symptom:** App crashed with `java.lang.IllegalStateException: Unable to bind to AudioService`.  
**Root Cause:** `AndroidManifest.xml` had the wrong service class name: `com.ryanheise.audioservice.AudioServiceActivity` (doesn't exist). Correct name is `AudioService`.  
**Fix:** Changed service `android:name` to `com.ryanheise.audioservice.AudioService`.

---

## [BUG-004] YouTube in-app search returned no results

**Date:** 2025-04  
**Symptom:** Searching on the YouTube Download screen showed a blank list with no results.  
**Root Cause:** `_yt.search.search()` returns `VideoSearchList` (a list of `Video` objects), but the code was filtering with `whereType<SearchVideo>()` — a different type — so everything was dropped silently.  
**Fix:** Removed `whereType<SearchVideo>()` and mapped directly over the `VideoSearchList`.

---

## [BUG-005] PlaylistsScreen TextEditingController disposed-after-use crash

**Date:** 2025-04  
**Symptom:** Intermittent crash when closing the "Create Playlist" dialog: `A TextEditingController was used after being disposed`.  
**Root Cause:** `.then((_) => controller.dispose())` ran during the dialog close animation, while the TextField was still using the controller.  
**Fix:** Extracted `_CreatePlaylistDialog` as a `StatefulWidget` that manages the controller's own lifecycle via `dispose()`.

---

## [BUG-006] Build failure — Namespace not specified for on_audio_query_android

**Date:** 2025-04  
**Symptom:** Gradle build failed with `Namespace not specified` for `on_audio_query_android-1.1.0`.  
**Root Cause:** Older package's `build.gradle` was missing the `namespace` field required by newer Android Gradle Plugin versions.  
**Fix:** Added `namespace 'com.lucasjosino.on_audio_query'` to the package's `build.gradle` in `.pub-cache`.

---

## [BUG-007] Build failure — Inconsistent JVM target between Java and Kotlin tasks

**Date:** 2025-04  
**Symptom:** Gradle build failed with `Inconsistent JVM-target compatibility detected for tasks 'compileDebugJavaWithJavac' (1.8) and 'compileDebugKotlin' (21)`.  
**Root Cause:** `on_audio_query_android` did not specify `compileOptions` or `kotlinOptions`, causing a mismatch between Java (1.8) and Kotlin (21) JVM targets.  
**Fix:** Added `compileOptions` and `kotlinOptions { jvmTarget = '1.8' }` to the package's `build.gradle`.

---

## [BUG-008] Install failure — INSTALL_FAILED_INSUFFICIENT_STORAGE

**Date:** 2025-04  
**Symptom:** APK built successfully but installation failed with `INSTALL_FAILED_INSUFFICIENT_STORAGE`.  
**Root Cause:** Emulator `/data` partition was at 93% capacity.  
**Fix:** Cleared all third-party app caches via `pm clear` for each installed package, freeing ~600MB.

---

## [BUG-009] flutter analyze errors after podcast removal — undefined_class Episode

**Date:** 2025-04  
**Symptom:** `flutter analyze` reported `undefined_class 'Episode'` in `mini_player_test.dart` after removing all podcast-related code.  
**Root Cause:** `FakeAudioNotifier` in the test file still overrode `playEpisode()` and `setPlaybackSpeed()` which no longer existed in `AudioNotifier`.  
**Fix:** Removed those method overrides from `FakeAudioNotifier`.

---

## [BUG-010] drift database.g.dart errors in VS Code (false positives)

**Date:** 2025-04  
**Symptom:** VS Code Problems panel showed hundreds of errors in `database.g.dart` (`undefined class`, `Value isn't a class`, etc.).  
**Root Cause:** VS Code Dart analysis server had a stale cache after `flutter pub get` restored drift packages.  
**Fix:** Ran **Dart: Restart Analysis Server** from VS Code Command Palette. `flutter analyze` confirmed no real errors.
