# Device Identity for Preview Abuse Prevention

**Date:** 2026-05-12 | **Status:** Implemented

## Problem

The 21-day preview uses `SharedPreferences`-stored timestamps. Uninstall/reinstall wipes these, allowing unlimited free previews. No user account, no PII, so we need anonymous, privacy-preserving identity that survives app reinstall.

## Architecture

Two platform-specific identifiers, hashed before transmission. Server-agnostic — identical treatment regardless of OS.

```
┌─────────────────────────────────────────────────────┐
│ Client                                              │
│                                                     │
│  iOS: DeviceCheck.currentDevice.generateToken()     │
│       → opaque blob from Apple, server validates    │
│                                                     │
│  Android: Settings.Secure.ANDROID_ID                │
│           → sha256(androidId)                       │
│                                                     │
│  Both → device_fingerprint: string                  │
│         sent to POST /api/entitlement/init          │
└─────────────────┬───────────────────────────────────┘
                  │ (never raw ID, always hashed/blinded)
                  ▼
┌─────────────────────────────────────────────────────┐
│ Server (Cloudflare Worker)                          │
│                                                     │
│  D1 table: device_fingerprints                      │
│  ┌──────────────────────┬──────────────┐            │
│  │ fingerprint          │ preview_used │            │
│  ├──────────────────────┼──────────────┤            │
│  │ abc123hash...        │ true         │            │
│  └──────────────────────┴──────────────┘            │
│                                                     │
│  Logic: if fingerprint exists → preview blocked     │
│         else → create preview + store fingerprint   │
└─────────────────────────────────────────────────────┘
```

## Platform Identifiers

### iOS — DeviceCheck

| Property | Detail |
|----------|--------|
| API | `DCDevice.currentDevice.generateToken()` |
| Persistence | 100% survives uninstall, reboot, OS update |
| Reset triggers | Factory reset, device replacement |
| Privacy | Zero PII. Apple-designated privacy API. Server never sees device serial. |
| Permission | None needed |
| Flutter | `device_check` package or platform channel |
| Server requirement | Apple private key (generated in App Store Connect), JWT-signed request to `api.development.devicecheck.apple.com` |

**Flow:**
1. iOS client calls `DCDevice.generateToken()` → opaque Data blob
2. Client sends blob to our server as `device_fingerprint`
3. Our server sends blob to Apple's DeviceCheck API (signed with our private key)
4. Apple returns 2-bit state — we read bit 0: "preview used"
5. Our server stores hash internally to avoid re-querying Apple for every request

### Android — Settings.Secure.ANDROID_ID

| Property | Detail |
|----------|--------|
| API | `Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)` |
| Persistence | Survives uninstall since Android 8.0 (95%+ active devices) |
| Reset triggers | Factory reset, app signature change |
| Privacy | Per-app-signing-key scoped. No PII. |
| Permission | None needed |
| Flutter | Platform channel or `device_info_plus` (via `androidId` getter) |

**Flow:**
1. Android client reads `ANDROID_ID`
2. Hashes it: `sha256(androidId + app_package_name)`
3. Sends hash as `device_fingerprint`
4. Server stores hash

### Survival Rate by Scenario

| Scenario | iOS (DeviceCheck) | Android (ANDROID_ID) |
|----------|:---:|:---:|
| Uninstall → reinstall | ✅ 100% | ✅ ~100% |
| OS update + reinstall | ✅ 100% | ✅ ~100% |
| Factory reset | ❌ Reset | ❌ Reset |
| New device | ❌ New ID | ❌ New ID |
| Time manipulation | ✅ Immune | ✅ Immune |

## Data Flow

### First Install (no prior preview)

```
App → DeviceCheck.generateToken() / sha256(ANDROID_ID)
    → POST /api/entitlement/init { device_id, device_fingerprint }
    → Server: no fingerprint match → create preview + store fingerprint
    → Response: { token, state: 'preview', preview_duration_days: 21 }
```

### Reinstall (preview already used)

```
App → DeviceCheck.generateToken() / sha256(ANDROID_ID)
    → POST /api/entitlement/init { device_id, device_fingerprint }
    → Server: fingerprint match found → preview already used
    → Response: { token, state: 'restricted', message: 'Preview already used on this device' }
    → Client: _applyLocalPreview() early-returns (state already restricted)
```

### Purchase (always allowed, fingerprint irrelevant)

```
Fingerprint has no effect on purchase flow. Purchase ties to Apple/Google account.
Server links receipt to device_id (not fingerprint).
```

## Privacy Analysis

| Concern | How Addressed |
|---------|---------------|
| PII collection | None. Device IDs are hashed before transmission. |
| User tracking | None. Fingerprint only used for binary "preview used?" check. |
| Apple compliance | DeviceCheck is Apple's privacy-first API. Approved for App Store. |
| Google compliance | Android ID requires no permissions. Standard practice. |
| GDPR | No personal data collected. Hashing = pseudonymization. |
| Data retention | Fingerprint → preview_used flag. No timestamps, no usage data. |
| Right to deletion | Fingerprint is anonymous hash. No way to identify individual. |
| Privacy Policy impact | Minimal. Already states "anonymous device identifier for trial management." |

## Implementation Plan

### Phase 1: Server (Cloudflare Worker)

**File:** `chorus-api/src/routes/entitlement.ts`

Changes to `handleInit()`:
1. Accept optional `device_fingerprint` in request body
2. Create new D1 table `device_fingerprints`:
   ```sql
   CREATE TABLE device_fingerprints (
     fingerprint TEXT PRIMARY KEY,
     preview_used BOOLEAN DEFAULT 1,
     created_at TEXT
   );
   ```
3. Logic:
   ```typescript
   if (body.device_fingerprint) {
     const existing = await DB.prepare(
       'SELECT preview_used FROM device_fingerprints WHERE fingerprint = ?'
     ).bind(body.device_fingerprint).first();
     
     if (existing?.preview_used) {
       // Preview already used on this device → restricted
       return { state: 'restricted', message: 'Preview already used' };
     }
     // Store fingerprint for future checks
     await DB.prepare(
       'INSERT INTO device_fingerprints (fingerprint, preview_used, created_at) VALUES (?, 1, ?)'
     ).bind(body.device_fingerprint, now).run();
   }
   ```
4. For paid users → skip fingerprint check entirely
5. Existing `device_id` flow unchanged for backward compatibility

**File:** `chorus-api/src/types.ts`

Add `device_fingerprints` to D1 type bindings.

### Phase 2: Client (Flutter)

**File:** `lib/core/services/device_fingerprint_service.dart` (NEW)

```dart
class DeviceFingerprintService {
  static Future<String?> getFingerprint() async {
    if (Platform.isIOS) {
      return await _getIOSDeviceCheckToken();
    } else if (Platform.isAndroid) {
      return await _getAndroidFingerprint();
    }
    return null;
  }
  
  // iOS: DeviceCheck token
  static Future<String?> _getIOSDeviceCheckToken() async { ... }
  
  // Android: sha256(ANDROID_ID + packageName)
  static Future<String?> _getAndroidFingerprint() async { ... }
}
```

**File:** `lib/core/services/entitlement_service.dart`

Modify `_callInit()`:
```dart
final deviceFingerprint = await DeviceFingerprintService.getFingerprint();
final body = {'device_id': deviceId};
if (deviceFingerprint != null) {
  body['device_fingerprint'] = deviceFingerprint;
}
```

### Phase 3: Testing

- [ ] iOS: uninstall → reinstall → verify preview blocked
- [ ] Android: uninstall → reinstall → verify preview blocked
- [ ] Factory reset → verify new preview granted (fair)
- [ ] Device switch → verify new preview granted (fair)
- [ ] Purchase still works regardless of fingerprint
- [ ] Existing preview users not broken (backward compat)

## Dependencies

| Package | Platform | Purpose |
|---------|----------|---------|
| `device_check` | iOS | DeviceCheck token generation |
| `crypto` | Both | SHA-256 hashing for Android |
| Platform channel | Android | `Settings.Secure.ANDROID_ID` read |

## Rollback Strategy

- Server: feature-gate via `ENTITLEMENT_FINGERPRINT_ENABLED` env var (default: `'false'` during rollout)
- Client: `device_fingerprint` is optional in request body — server ignores when missing
- If server rejects with error, client falls back to existing local-only preview
- Can disable entirely by removing env var on server — zero client changes needed

## Questions / Decisions Pending

- [ ] Do we need `device_check` Flutter package or write platform channel directly?
- [ ] iOS DeviceCheck server: use existing Cloudflare Worker or separate edge function?
- [x] Sent on `/init` only — fingerprint is checked at preview creation time
- [x] Existing preview users: grandfathered. Fingerprint stored on next init call. No retroactive blocking.
- [x] Factory reset: intentionally allows fresh preview. Rationale below.

## Factory Reset Decision

**Question:** Should a factory reset device be given a fresh 21-day preview?

**Industry practice:** Most apps allow factory-reset devices a new trial because:
1. Factory reset implies significant user intent (not casual abuse)
2. Device-level restrictions create a poor UX for genuine device upgrades or resets
3. The friction of a factory reset outweighs the $19.99 one-time purchase price

**Our decision: Allow fresh preview after factory reset.**

Both platform identifiers regenerate:
- iOS: `identifierForVendor` changes when all vendor apps are removed (factory reset does this)
- Android: `Settings.Secure.ANDROID_ID` regenerates on factory reset

This is consistent with the goal: block casual reinstalls (uninstall → reinstall), not device-level events. The $19.99 price point and journaling niche make factory reset an impractical abuse vector.
