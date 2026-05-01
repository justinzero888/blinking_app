import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

enum TrialStatus { none, active, expired }

class TrialService {
  static const _trialBaseUrl = 'https://blinkingchorus.com/api/trial';
  static const _prefsKeyPrefix = 'trial_';
  static const _trialDurationDays = 7;

  final SharedPreferences _prefs;

  TrialService(this._prefs);

  Future<String> startTrial() async {
    final deviceId = await DeviceService.getDeviceId();
    final response = await http.post(
      Uri.parse('$_trialBaseUrl/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      await _saveTrialData(token, DateTime.now());
      return token;
    } else if (response.statusCode == 429) {
      throw TrialException('trial_already_used', 'Trial already used on this device.');
    } else {
      throw TrialException('start_failed', 'Failed to start trial (HTTP ${response.statusCode}).');
    }
  }

  Future<String> startDemoTrial() async {
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final token = 'demo_${List.generate(28, (_) => chars[Random().nextInt(chars.length)]).join()}';
    await _saveTrialData(token, DateTime.now());
    await _prefs.setBool('${_prefsKeyPrefix}demo', true);
    return token;
  }

  bool get isDemoTrial => _prefs.getBool('${_prefsKeyPrefix}demo') ?? false;

  TrialStatus getStatus() {
    final token = _prefs.getString('${_prefsKeyPrefix}token');
    if (token == null || token.isEmpty) return TrialStatus.none;
    final startedAtStr = _prefs.getString('${_prefsKeyPrefix}started_at');
    if (startedAtStr == null) return TrialStatus.none;
    final startedAt = DateTime.parse(startedAtStr);
    final expiryDate = startedAt.add(const Duration(days: _trialDurationDays));
    if (DateTime.now().isAfter(expiryDate)) return TrialStatus.expired;
    return TrialStatus.active;
  }

  int get trialDaysLeft {
    final startedAtStr = _prefs.getString('${_prefsKeyPrefix}started_at');
    if (startedAtStr == null) return 0;
    final startedAt = DateTime.parse(startedAtStr);
    final expiryDate = startedAt.add(const Duration(days: _trialDurationDays));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  String? get trialToken => _prefs.getString('${_prefsKeyPrefix}token');

  Map<String, String> buildTrialProvider() {
    return {
      'name': 'Trial',
      'model': 'qwen/qwen3.5-flash-02-23',
      'apiKey': trialToken ?? '',
      'baseUrl': '$_trialBaseUrl/chat',
    };
  }

  Future<void> clearTrial() async {
    await _prefs.remove('${_prefsKeyPrefix}token');
    await _prefs.remove('${_prefsKeyPrefix}started_at');
    await _prefs.remove('${_prefsKeyPrefix}demo');
  }

  Future<void> _saveTrialData(String token, DateTime startedAt) async {
    await _prefs.setString('${_prefsKeyPrefix}token', token);
    await _prefs.setString('${_prefsKeyPrefix}started_at', startedAt.toIso8601String());
  }
}

class TrialException implements Exception {
  final String code;
  final String message;
  TrialException(this.code, this.message);
}
