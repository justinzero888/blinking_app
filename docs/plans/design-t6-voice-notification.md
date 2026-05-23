# T-6: Voice Notification — Design Document

> **Phase:** 2 | **Effort:** ~2h | **Files impacted:** 5  
> **Design principle:** Voice output only. No microphone. Ever.

---

## Architecture Overview

```
User saves routine with reminder + voice enabled
         │
         ▼
RoutineProvider.updateRoutine() → NotificationService.scheduleRoutine()
         │                                        │
         │               VoiceNotificationService.enqueue(routineId, text, locale)
         │                                        │
         ▼                                        ▼
fluter_local_notifications                flutter_tts
   zonedSchedule()                           speak()
         │                                        │
         ▼                                        ▼
   Notification fires at scheduled time     If app in foreground:
         │                                   TTS speaks routine name + description
         ▼                                   If app in background:
   OS displays banner notification              Banner notification only (no TTS)
```

### Scope boundary

| Context | TTS Behavior |
|---------|-------------|
| **App in foreground** | Speak name + description immediately when notification fires |
| **App in background** | Visual notification only (routine name shown in banner). No TTS. |
| **User taps notification** | Open app. Optionally speak the tapped routine. |

**Why no background TTS?** Generating audio files for background playback requires `synthesizeToFile`, temporary file management, and platform-specific notification sound configuration. ~4h extra effort. Deferred to v1.3.0.

---

## Data Model Changes

### Routine model (`lib/models/routine.dart`)

Add one field:

```dart
final bool voiceEnabled;  // defaults to false

Routine({
  // ... existing fields ...
  this.voiceEnabled = false,  // NEW
});
```

Add to `copyWith`:
```dart
bool? voiceEnabled,
// ...
voiceEnabled: voiceEnabled ?? this.voiceEnabled,
```

Add to `toJson()`:
```dart
'voiceEnabled': voiceEnabled,
```

Add to `fromJson()`:
```dart
voiceEnabled: json['voiceEnabled'] as bool? ?? false,
```

### SharedPreferences (new key)

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `voice_notifications_enabled` | bool | `false` | Global master toggle. Per-routine toggle only works when global is on. |

### DB migration (v14)

Add `voice_enabled INTEGER NOT NULL DEFAULT 0` column to `routines` table.  
*(Note: v14 migration already planned for card system. Add this column now to avoid double migration.)*

---

## New Service: `VoiceNotificationService`

**File:** `lib/core/services/voice_notification_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceNotificationService {
  static final _tts = FlutterTts();
  static bool _initialized = false;
  static String _currentLanguage = 'en-US';

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.45);   // calm pace
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.8);
    _initialized = true;
    _log('Initialized');
  }

  /// Speak a routine reminder in the given language.
  /// Silently no-ops if TTS is unavailable (no crash).
  static Future<void> speak(String text, {required String language}) async {
    if (!_initialized) {
      _log('speak() called before init — ignoring');
      return;
    }
    try {
      // Switch language if different from last call
      if (language != _currentLanguage) {
        await _tts.setLanguage(language);
        _currentLanguage = language;
      }
      _log('Speaking: "$text" ($language)');
      await _tts.speak(text);
    } catch (e) {
      _log('TTS error: $e');
    }
  }

  /// Stop any ongoing speech (user dismisses notification).
  static Future<void> stop() async {
    try { await _tts.stop(); } catch (_) {}
  }

  static void _log(String msg) {
    debugPrint('🔊 [Voice] $msg');
  }
}
```

**Design notes:**
- `speechRate: 0.45` — calm, deliberate pace. Slightly slower than default (0.5).
- `volume: 0.8` — loud enough to hear, won't startle.
- Single static instance. No need for ChangeNotifier — service is command-based.
- `catch (e)` on every call. TTS failure must never crash the app.

---

## Integration: Notification Pipeline

### Current flow (`NotificationService.scheduleRoutine()`)

```
1. Validate routine (active, has reminderTime)
2. Cancel previous notification
3. Parse HH:mm
4. Build title (icon) + body (routine.displayName)
5. zonedSchedule() with NotificationDetails
```

### Modified flow

```
1-3. Same
4. Build title (icon) + body (routine.displayName + description)
5. Build voiceText from routine.displayName + displayDescription
6. zonedSchedule() with NotificationDetails
7. If voice enabled globally AND per-routine → store voice text for foreground callback
```

### Notification details update

The notification body currently shows only the routine name. Add description:

```dart
// Before:
final body = routine.displayName(isZh);

// After:
final body = routine.displayName(isZh);
if (routine.displayDescription(isZh) != null && routine.displayDescription(isZh).isNotEmpty) {
  body += '\n${routine.displayDescription(isZh)}';
}
```

The description line already exists on the Routine model as `description`/`descriptionEn` with a `displayDescription` getter (need to add if not present).

### Foreground callback

`flutter_local_notifications` can fire a callback when a notification is displayed while app is in foreground. Use this to trigger TTS:

```dart
// In NotificationService.init():
final iosForegroundSettings = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: false,
  presentSound: false,
  presentBanner: true,
  presentList: true,
);
```

And listen for the notification display callback (platform-specific):

```dart
_plugin.initialize(
  settings: const InitializationSettings(...),
  onDidReceiveNotificationResponse: _onNotificationTap,
  // iOS foreground callback:
  onDidReceiveLocalNotification: _onForegroundNotification,
);
```

```dart
static void _onForegroundNotification(
  int id, String? title, String? body, String? payload) {
  // Only speak if voice is enabled
  // The payload contains the voice text (pre-built by scheduleRoutine)
  if (payload != null && payload.isNotEmpty) {
    final parts = payload.split('|'); // format: "lang|text"
    if (parts.length == 2) {
      VoiceNotificationService.speak(parts[1], language: parts[0]);
    }
  }
}
```

Wait — `onDidReceiveLocalNotification` is iOS-only and deprecated. For Android, there's no foreground notification delivery callback in `flutter_local_notifications`. 

**Simpler approach:** Instead of relying on notification callbacks, just trigger TTS at the moment the notification is scheduled for routines with reminders < 2 minutes in the future. For real-time reminders (when app is open), speak immediately. For future reminders, the notification banner is sufficient.

Actually, the cleanest approach for v1.2.0: **Only speak for foreground-perceived notifications.** This means:

1. When app launches, check if any routine reminder just fired (<2 min ago) → speak it
2. When user opens the app and a routine is due NOW → speak it
3. Scheduled notifications work as text-only (already working)

This is simple, reliable, and covers the main use case: user has the app open, a reminder time hits, and they hear it.

For a practical flow:
```dart
// In HomeScreen or main.dart after rescheduleAll():
final now = DateTime.now();
for (final r in routines) {
  if (r.isActive && r.reminderTime != null && r.voiceEnabled) {
    final parts = r.reminderTime!.split(':');
    final reminderHour = int.parse(parts[0]);
    final reminderMinute = int.parse(parts[1]);
    final reminderToday = DateTime(now.year, now.month, now.day, reminderHour, reminderMinute);
    if (reminderToday.isBefore(now) && now.difference(reminderToday).inMinutes < 2) {
      // Just missed — speak it now
      VoiceNotificationService.speak(r.displayName(isZh), language: isZh ? 'zh-CN' : 'en-US');
    }
  }
}
```

This is ~20 lines, no platform API gymnastics. Clean, testable, reliable.

Let me finalize the design with this simplified approach.

---

## Implementation Plan

### Step 1: Add `flutter_tts` dependency + permissions

```bash
flutter pub add flutter_tts
```

No additional permissions needed on iOS (TTS uses `AVSpeechSynthesizer`, no mic).  
Android: `flutter_tts` handles permissions internally. No manifest changes needed.

### Step 2: Add `voiceEnabled` to Routine model

Add field, update `fromJson`/`toJson`/`copyWith`. Default `false`.

### Step 3: DB migration v14 (prep for card system)

Add `voice_enabled INTEGER NOT NULL DEFAULT 0` to `routines` table now.  
*Combined with card system's template columns later in Phase 3.*

### Step 4: Create `VoiceNotificationService`

As designed above — static service with `init()`, `speak()`, `stop()`.

### Step 5: Add global toggle to Settings

Settings → General → "Voice Reminders" SwitchListTile.  
Reads/writes `voice_notifications_enabled` SharedPreferences key.  
When toggled ON: call `VoiceNotificationService.init()`.  
When toggled OFF: call `VoiceNotificationService.stop()`.

### Step 6: Add per-routine toggle to routine dialog

In the routine add/edit dialog, below the reminder time field:
- `SwitchListTile` — "Speak reminder" (visible only if global voice is ON)
- Saves to `routine.voiceEnabled`

### Step 7: Wire into HomeScreen after reschedule

In `HomeScreen` (or wherever `rescheduleAll` is called), after scheduling:
```dart
if (globalVoiceEnabled) {
  for (final r in routines.where(...)) {
    // Check if routine just passed its reminder time (< 2 min)
    // If yes, speak it
  }
}
```

### Step 8: Speak on notification tap

When user taps a routine notification → open app → speak the routine.

---

## Settings UI

```
Settings → General
┌──────────────────────────────────────────┐
│  Language          English     >         │
│  Theme             System      >         │
│  ────────────────────────────────────    │
│  Voice Reminders     [ Switch ]          │
│  Speak routine names when reminders fire │
│                                          │
│  Privacy                                      │
│  Export / Import                              │
└──────────────────────────────────────────┘
```

---

## Routine Dialog UI (voice toggle)

```
┌──────────────────────────────────────────┐
│  Routine Name     [________________   ]   │
│  Icon             [ picker ]             │
│  Why this matters [________________   ]   │
│  Reminder         [ 21:00 ]             │
│  ─────────────────────────────────────── │
│  🔊 Speak reminder    [ Switch ]         │  ← NEW (only if global voice ON)
│      Reads the routine aloud at reminder │
│      time when app is open               │
└──────────────────────────────────────────┘
```

---

## Test Cases

### Unit Tests

| ID | Test | Expected |
|----|------|----------|
| UT-1 | `VoiceNotificationService.speak()` calls `flutter_tts.speak()` with correct params | Mocked TTS receives text + language |
| UT-2 | `VoiceNotificationService.speak()` switches language from EN to ZH | TTS `setLanguage('zh-CN')` called before speak |
| UT-3 | `VoiceNotificationService.speak()` handles TTS error gracefully | Exception caught, no crash, `debugPrint` logged |
| UT-4 | `VoiceNotificationService.stop()` handles TTS unavailable | Exception caught, no crash |
| UT-5 | `Routine.voiceEnabled` defaults to `false` | New routine has `voiceEnabled == false` |
| UT-6 | `Routine.fromJson()` reads `voiceEnabled` from JSON | `{'voiceEnabled': true}` → `routine.voiceEnabled == true` |
| UT-7 | `Routine.toJson()` writes `voiceEnabled` to JSON | Round-trip preserves value |
| UT-8 | Global toggle reads/writes SharedPreferences | Toggle on → `voice_notifications_enabled = true` persisted |

### Widget Tests

| ID | Test | Expected |
|----|------|----------|
| WT-1 | Settings shows "Voice Reminders" toggle | SwitchListTile rendered in Settings → General |
| WT-2 | Toggle OFF by default on fresh install | `voice_notifications_enabled` is `false` |
| WT-3 | Per-routine toggle hidden when global voice is OFF | No "Speak reminder" switch in routine dialog |
| WT-4 | Per-routine toggle visible when global voice is ON | "Speak reminder" switch appears in routine dialog |

### Integration Tests

| ID | Test | Expected |
|----|------|----------|
| IT-1 | Create routine with voice ON, reminder fires, app in foreground | TTS speaks routine name + description |
| IT-2 | Create routine with voice OFF, reminder fires | Silent notification only |
| IT-3 | Switch language ZH → EN, create voice routine | TTS speaks in English |
| IT-4 | Toggle global voice OFF while routine has voice ON | Routine reminder is silent |

---

## UAT Cases

| ID | Test | Device | Steps | Expected |
|----|------|--------|-------|----------|
| V-1 | Voice: routine fires in foreground | iPhone 17 Pro | Create routine with reminder 2min from now, voice ON, keep app open | TTS speaks "Time for [routine name]" at scheduled time |
| V-2 | Voice: app in background | iPhone 17 Pro | Create routine with voice ON, minimize app | Visual notification appears, no TTS |
| V-3 | Voice: language switch EN → ZH | iPhone 17 Pro | Set locale to 中文, create ZH-named routine, voice ON | TTS speaks in Chinese (zh-CN voice) |
| V-4 | Voice: language switch ZH → EN | iPhone 17 Pro | Set locale to English, create EN-named routine, voice ON | TTS speaks in English (en-US voice) |
| V-5 | Voice: toggle OFF globally | iPhone 17 Pro | Settings → Voice OFF, create routine with voice ON | Routine fires silently |
| V-6 | Voice: per-routine toggle | iPhone 17 Pro | Global voice ON, routine A voice ON, routine B voice OFF | A speaks, B silent |
| V-7 | Voice: routine fires, app in foreground | Android emulator | Same as V-1 | TTS speaks routine name |
| V-8 | Voice: TTS unavailable gracefully | Android emulator | Simulate TTS engine not installed | No crash, visual notification still appears |
| V-9 | Voice: stop speech on app close | iPhone 17 Pro | TTS speaking, force-close app | Speech stops, no audio leak |

---

## Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_tts` dependency |
| `lib/models/routine.dart` | Add `voiceEnabled` field + `fromJson`/`toJson`/`copyWith` |
| `lib/core/services/database_service.dart` | v14 migration: add `voice_enabled` column |
| `lib/core/services/voice_notification_service.dart` | **NEW** — static TTS service |
| `lib/core/services/notification_service.dart` | Build voice text payload, call TTS on foreground delivery |
| `lib/screens/settings/settings_screen.dart` | Add global "Voice Reminders" toggle |
| `lib/screens/routine/routine_screen.dart` | Add per-routine "Speak reminder" toggle in dialog |
| `lib/main.dart` or `lib/app.dart` | Check for just-missed reminders and speak |
