import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

enum EntitlementState {
  preview,
  restricted,
  paid,
}

enum AISource {
  managed,
  byok,
  none,
}

enum AIButtonVisual {
  active,
  dormant,
  dormantWarn,
  hidden,
  pulsing,
}

class EntitlementService extends ChangeNotifier {
  static const _baseUrl = 'https://blinkingchorus.com/api/entitlement';
  static const _jwtKey = 'entitlement_jwt';
  static const _stateKey = 'entitlement_state';
  static const _quotaKey = 'entitlement_quota';
  static const _quotaDateKey = 'entitlement_quota_date';
  static const _previewStartedKey = 'entitlement_preview_started';
  static const _previewDaysKey = 'entitlement_preview_days';

  static const _previewTotalDays = 21;
  static const _previewDailyQuota = 3;
  static const _restrictedMonthlyQuota = 3;

  SharedPreferences? _prefs;
  String? _jwt;
  EntitlementState _state = EntitlementState.restricted;
  int _quotaRemaining = 0;
  String _quotaSource = 'none';
  String _quotaRefill = '';
  int _previewDaysRemaining = 0;
  bool _initialized = false;
  bool _initInProgress = false;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;

    _jwt = prefs.getString(_jwtKey);
    _state = _parseState(prefs.getString(_stateKey));
    _quotaRemaining = prefs.getInt(_quotaKey) ?? 0;
    _previewDaysRemaining = prefs.getInt(_previewDaysKey) ?? 0;

    if (_jwt != null && _jwt!.isNotEmpty) {
      await _refreshStatus();
    } else {
      await _callInit();
    }

    // Offline fallback: if no JWT, ensure local preview is active
    if (_jwt == null || _jwt!.isEmpty) {
      _applyLocalPreview();
    }

    _initialized = true;
    notifyListeners();
  }

  // ── Local / Offline Preview ─────────────────────────────────────────

  void _applyLocalPreview() {
    // Don't override an explicit restricted or paid state
    if (_state == EntitlementState.restricted || _state == EntitlementState.paid) {
      return;
    }
    final now = DateTime.now();
    final today = _dateKey(now);

    final startedStr = _prefs?.getString(_previewStartedKey);
    if (startedStr == null) {
      // First time: start local preview. If we already have a saved
      // days-remaining that is less than total, backfill the start date.
      final savedDays = _prefs?.getInt(_previewDaysKey) ?? 0;
      if (savedDays > 0 && savedDays < _previewTotalDays) {
        final estimatedStart = now.subtract(Duration(days: _previewTotalDays - savedDays));
        _prefs?.setString(_previewStartedKey, estimatedStart.toIso8601String());
      } else {
        _prefs?.setString(_previewStartedKey, now.toIso8601String());
      }
      _previewDaysRemaining = savedDays > 0 && savedDays < _previewTotalDays
          ? savedDays
          : _previewTotalDays;
      _state = EntitlementState.preview;
      _quotaRemaining = _previewDailyQuota;
      _quotaSource = 'preview_daily';
      _quotaRefill = 'Tomorrow';
      _prefs?.setString(_quotaDateKey, today);
      _prefs?.setString('trial_token', 'preview_local');
      if (_prefs?.getString('trial_started_at') == null) {
        _prefs?.setString('trial_started_at', now.toIso8601String());
      }
      _saveState();
      return;
    }

    final started = DateTime.tryParse(startedStr);
    if (started == null) return;

    final daysElapsed = now.difference(started).inDays;
    _previewDaysRemaining = (_previewTotalDays - daysElapsed).clamp(0, _previewTotalDays);

    if (_previewDaysRemaining <= 0) {
      _state = EntitlementState.restricted;
      _quotaSource = 'restricted_monthly';
      _quotaRefill = 'Monthly';
      _previewDaysRemaining = 0;
      _prefs?.setBool('entitlement_was_preview', true);
      _saveState();
      return;
    }

    _state = EntitlementState.preview;
    _prefs?.setBool('entitlement_was_preview', true);

    // Reset daily quota if it's a new day
    final lastQuotaDate = _prefs?.getString(_quotaDateKey);
    if (lastQuotaDate != today) {
      _quotaRemaining = _previewDailyQuota;
      _prefs?.setString(_quotaDateKey, today);
    }

    _quotaSource = 'preview_daily';
    _quotaRefill = 'Tomorrow';
    _saveState();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Server Calls ────────────────────────────────────────────────────

  Future<void> _callInit() async {
    if (_initInProgress) return;
    _initInProgress = true;

    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.post(
        Uri.parse('$_baseUrl/init'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwt = data['token'] as String;
        _state = _parseState(data['state'] as String?);
        _quotaRemaining = data['max_requests_per_day'] ?? _previewDailyQuota;
        _quotaSource = 'preview_daily';
        _quotaRefill = 'Tomorrow';
        _previewDaysRemaining = data['preview_duration_days'] ?? _previewTotalDays;
        await _saveState();
      }
    } catch (_) {
      // Offline: use cached state
    }

    _initInProgress = false;
    notifyListeners();
  }

  Future<void> _refreshStatus() async {
    if (_jwt == null || _jwt!.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: {'Authorization': 'Bearer $_jwt'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prevState = _state;
        _state = _parseState(data['state'] as String?);
        _jwt = data['token'] as String? ?? _jwt;

        final quota = data['quota'] as Map<String, dynamic>?;
        if (quota != null) {
          _quotaRemaining = quota['remaining'] as int? ?? 0;
          _quotaSource = quota['source'] as String? ?? 'none';
          _quotaRefill = quota['refillLabel'] as String? ?? '';
        }

        _previewDaysRemaining = data['preview_days_remaining'] as int? ?? 0;

        if (data['preview_started_at'] != null) {
          await _prefs?.setString(
              _previewStartedKey, data['preview_started_at'] as String);
        }

        // Track if user was ever in PREVIEW (for transition screen trigger)
        if (prevState == EntitlementState.preview && _state == EntitlementState.restricted) {
          await _prefs?.setBool('entitlement_was_preview', true);
        }
        if (_state == EntitlementState.preview) {
          await _prefs?.setBool('entitlement_was_preview', true);
        }

        await _saveState();
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        _jwt = null;
        await _callInit();
      }
    } catch (_) {}

    notifyListeners();
  }

  bool get wasPreview => _prefs?.getBool('entitlement_was_preview') ?? false;

  Future<void> refresh() => _refreshStatus();

  // ── State ──────────────────────────────────────────────────────────

  EntitlementState get currentState => _state;

  bool get hasOwnKey {
    if (_prefs == null) return false;
    final jsonStr = _prefs!.getString('llm_providers');
    if (jsonStr == null || jsonStr.isEmpty) return false;
    try {
      final providers = jsonDecode(jsonStr) as List<dynamic>;
      for (final p in providers) {
        if (p is Map) {
          final apiKey = p['apiKey'] as String? ?? '';
          final name = p['name'] as String? ?? '';
          if (apiKey.isNotEmpty && name != 'Trial' && name != '7-Day Trial') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  bool get hasActiveBYOK => hasOwnKey;

  AISource get aiSource {
    if (hasActiveBYOK) return AISource.byok;
    if (_state == EntitlementState.preview) return AISource.managed;
    if (_state == EntitlementState.paid) return AISource.managed;
    return AISource.none;
  }

  // ── AI Access ──────────────────────────────────────────────────────

  bool get canUseAI {
    if (hasActiveBYOK) return true;
    if (_state == EntitlementState.preview && _quotaRemaining > 0) return true;
    if (_state == EntitlementState.restricted && _quotaRemaining > 0) return true;
    if (_state == EntitlementState.paid && _quotaRemaining > 0) return true;
    return false;
  }

  int get remainingAI {
    if (hasActiveBYOK) return -1;
    return _quotaRemaining;
  }

  String? get entitlementJwt => _jwt;

  // ── Quota display ──────────────────────────────────────────────────

  String get quotaRefillLabel {
    if (hasActiveBYOK) return '';
    if (_quotaRefill.isNotEmpty) return _quotaRefill;
    return '';
  }

  String get aiSourceLabel {
    switch (aiSource) {
      case AISource.managed:
        if (_state == EntitlementState.preview) return 'Preview';
        if (_state == EntitlementState.restricted) return 'Taste';
        return 'Quota';
      case AISource.byok:
        return 'Your key';
      case AISource.none:
        return 'None';
    }
  }

  // ── AI Button State Machine ────────────────────────────────────────

  AIButtonVisual get buttonVisual {
    if (_state == EntitlementState.preview && _quotaRemaining > 0) {
      return AIButtonVisual.active;
    }
    if (_state == EntitlementState.restricted && _quotaRemaining > 0) {
      return AIButtonVisual.active;
    }
    if (_state == EntitlementState.paid && _quotaRemaining > 0) {
      return AIButtonVisual.active;
    }
    if (hasActiveBYOK && !_isBYOKKeyValid()) {
      return AIButtonVisual.dormantWarn;
    }
    if (hasActiveBYOK) return AIButtonVisual.active;
    return AIButtonVisual.dormant;
  }

  bool _isBYOKKeyValid() {
    if (!hasActiveBYOK || _prefs == null) return false;
    return _prefs!.getBool('entitlement_byok_validated') ?? true;
  }

  int get previewDaysRemaining => _previewDaysRemaining;
  int get previewDaysTotal => _previewTotalDays;
  int get previewDailyQuota => _previewDailyQuota;
  int get restrictedMonthlyQuota => _restrictedMonthlyQuota;

  bool get isPreviewActive => _state == EntitlementState.preview;
  bool get isRestricted => _state == EntitlementState.restricted;
  bool get isPaid => _state == EntitlementState.paid;

  // ── Feature Gates ──────────────────────────────────────────────────

  bool get canAddHabit => _state != EntitlementState.restricted;
  bool get canEditNote => _state != EntitlementState.restricted;
  bool get canBackup => _state != EntitlementState.restricted;
  bool get canExport => true;

  // ── Persistence ────────────────────────────────────────────────────

  Future<void> _saveState() async {
    if (_prefs == null) return;
    if (_jwt != null) await _prefs!.setString(_jwtKey, _jwt!);
    await _prefs!.setString(_stateKey, _state.name);
    await _prefs!.setInt(_quotaKey, _quotaRemaining);
    await _prefs!.setInt(_previewDaysKey, _previewDaysRemaining);
  }

  EntitlementState _parseState(String? s) {
    switch (s) {
      case 'paid':
        return EntitlementState.paid;
      case 'restricted':
        return EntitlementState.restricted;
      case 'preview':
      default:
        return EntitlementState.preview;
    }
  }
}
