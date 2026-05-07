import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal LLM client — reads provider config saved by settings_screen.dart
/// and calls the OpenAI-compatible chat completions endpoint.
///
/// Provider config stored in SharedPreferences:
///   llm_providers  → JSON array of { name, model, apiKey, baseUrl }
///   llm_selected_index → int
class LlmService {
  static const _defaultTimeout = Duration(seconds: 60);
  static const _trialApiKey = String.fromEnvironment('TRIAL_API_KEY');
  static const _proApiKey = String.fromEnvironment('PRO_API_KEY');

  /// Send a single-turn prompt and return the assistant's reply text.
  /// Throws [LlmException] if no provider is configured or the call fails.
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final config = await _loadConfig();

    final baseUrl = (config['baseUrl'] as String?)?.trimRight().replaceAll(RegExp(r'/$'), '');
    final apiKey = config['apiKey'] as String? ?? '';
    final model = config['model'] as String? ?? 'gpt-4o';

    if (baseUrl == null || baseUrl.isEmpty || apiKey.isEmpty) {
      throw LlmException('No API key configured.', LlmErrorType.noApiKey);
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    return _callChatCompletions(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      messages: messages,
    );
  }

  /// Multi-turn chat. [history] is a list of ChatMessage-like maps with
  /// 'role' ('user'|'assistant') and 'content'.
  Future<String> chat({
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    final config = await _loadConfig();

    final baseUrl = (config['baseUrl'] as String?)?.trimRight().replaceAll(RegExp(r'/$'), '');
    final apiKey = config['apiKey'] as String? ?? '';
    final model = config['model'] as String? ?? 'gpt-4o';

    if (baseUrl == null || baseUrl.isEmpty || apiKey.isEmpty) {
      throw LlmException('No API key configured.', LlmErrorType.noApiKey);
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.addAll(history);

    return _callChatCompletions(
      baseUrl: baseUrl,
      apiKey: apiKey,
      model: model,
      messages: messages,
    );
  }

  Future<String> _callChatCompletions({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final isTrialEndpoint = baseUrl.endsWith('/chat');
    final url = isTrialEndpoint
        ? Uri.parse(baseUrl)
        : Uri.parse('$baseUrl/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw LlmException('Empty response from API.', LlmErrorType.emptyResponse);
        }
        final content = choices[0]['message']['content'] as String?;
        return content ?? '';
      } else {
        debugPrint('LlmService HTTP ${response.statusCode}: ${response.body}');
        String detail = '';
        try {
          final err = jsonDecode(response.body);
          detail = err['error']?['message'] as String? ?? '';
        } catch (_) {}

        final status = response.statusCode;
        if (status == 401 || status == 403) {
          try {
            final err = jsonDecode(response.body);
            if (err['error'] == 'trial_expired') {
              throw LlmException('HTTP $status: $detail', LlmErrorType.trialExpired);
            }
          } catch (_) {}
          throw LlmException('HTTP $status: $detail', LlmErrorType.invalidApiKey);
        } else if (status == 429) {
          throw LlmException('HTTP $status: $detail', LlmErrorType.rateLimited);
        } else if (status >= 500) {
          throw LlmException('HTTP $status: $detail', LlmErrorType.serverError);
        } else {
          throw LlmException('HTTP $status: $detail', LlmErrorType.unknown);
        }
      }
    } on LlmException {
      rethrow;
    } on TimeoutException {
      throw LlmException('Request timed out.', LlmErrorType.timeout);
    } catch (e) {
      throw LlmException('Network error: $e', LlmErrorType.networkError);
    }
  }

  /// Returns true if the currently selected provider has a non-empty API key,
  /// or if a built-in key (trial/pro) is available.
  static Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('llm_providers');
    if (jsonStr != null) {
      try {
        final providers = jsonDecode(jsonStr) as List<dynamic>;
        if (providers.isNotEmpty) {
          final selectedIdx = prefs.getInt('llm_selected_index') ?? 0;
          final idx = selectedIdx.clamp(0, providers.length - 1);
          final provider = providers[idx] as Map<String, dynamic>;
          final apiKey = provider['apiKey'] as String? ?? '';
          if (apiKey.isNotEmpty) return true;
        }
      } catch (_) {}
    }
    // Check built-in keys based on entitlement state
    final state = prefs.getString('entitlement_state') ?? 'preview';
    if (state == 'preview' && _trialApiKey.isNotEmpty) return true;
    if ((state == 'paid' || state == 'restricted') && _proApiKey.isNotEmpty) return true;
    return false;
  }

  static bool _hasActiveTrial(SharedPreferences prefs) {
    final state = prefs.getString('entitlement_state') ?? 'preview';
    return state == 'preview' || state == 'paid' || state == 'restricted';
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. BYOK takes priority — user's own key always wins
    final jsonStr = prefs.getString('llm_providers');
    if (jsonStr != null) {
      try {
        final providers = jsonDecode(jsonStr) as List<dynamic>;
        if (providers.isNotEmpty) {
          final selectedIdx = prefs.getInt('llm_selected_index') ?? 0;
          final idx = selectedIdx.clamp(0, providers.length - 1);
          final provider = providers[idx] as Map<String, dynamic>;
          final apiKey = provider['apiKey'] as String? ?? '';
          if (apiKey.isNotEmpty) return provider;
        }
      } catch (_) {}
    }

    // 2. No BYOK — use built-in keys based on entitlement state
    final state = prefs.getString('entitlement_state') ?? 'preview';

    Map<String, String>? builtIn;
    if (state == 'preview' && _trialApiKey.isNotEmpty) {
      builtIn = {'name': 'Blinking Trial', 'apiKey': _trialApiKey};
    } else if ((state == 'paid' || state == 'restricted') && _proApiKey.isNotEmpty) {
      builtIn = {'name': 'Blinking Pro', 'apiKey': _proApiKey};
    }

    if (builtIn != null) {
      return {
        'name': builtIn['name']!,
        'model': 'qwen/qwen3.5-flash-02-23',
        'apiKey': builtIn['apiKey']!,
        'baseUrl': 'https://openrouter.ai/api/v1',
      };
    }

    return {};
  }
}

enum LlmErrorType {
  noApiKey,       // key not configured
  invalidApiKey,  // 401 — key rejected or expired
  rateLimited,    // 429 — quota / rate limit
  serverError,    // 5xx — provider side issue
  networkError,   // socket / DNS failure
  timeout,        // request timed out
  emptyResponse,  // 200 but no content
  trialExpired,   // trial token expired (7-day limit)
  unknown,
}

class LlmException implements Exception {
  final String message;
  final LlmErrorType type;

  LlmException(this.message, [this.type = LlmErrorType.unknown]);

  /// Returns a concise, user-friendly message in the requested language.
  String friendlyMessage(bool isZh) {
    switch (type) {
      case LlmErrorType.noApiKey:
        return isZh
            ? '尚未配置 API Key，请前往设置 → AI 服务配置中填写。'
            : 'No API key configured. Go to Settings → AI Provider to set it up.';
      case LlmErrorType.invalidApiKey:
        return isZh
            ? 'API Key 无效或已过期，请在设置中更新。'
            : 'API key is invalid or expired. Please update it in Settings.';
      case LlmErrorType.rateLimited:
        return isZh
            ? '请求频率超限或额度已用尽，请稍后再试或检查账户用量。'
            : 'Rate limit reached or quota exceeded. Please wait and try again, or check your account usage.';
      case LlmErrorType.serverError:
        return isZh
            ? 'AI 服务暂时不可用，请稍后重试。'
            : 'The AI provider is temporarily unavailable. Please try again later.';
      case LlmErrorType.networkError:
        return isZh
            ? '网络连接失败，请检查网络后重试。'
            : 'Network connection failed. Please check your connection and try again.';
      case LlmErrorType.timeout:
        return isZh
            ? '请求超时，AI 服务响应过慢，请稍后重试。'
            : 'Request timed out. The AI service is responding slowly — please try again.';
      case LlmErrorType.emptyResponse:
        return isZh
            ? 'AI 返回了空响应，请重试。'
            : 'The AI returned an empty response. Please try again.';
      case LlmErrorType.trialExpired:
        return isZh
            ? '试用已过期。请在设置中添加您自己的 API Key 以继续使用 AI 助手。'
            : 'Your trial has expired. Add your own API key in Settings to continue.';
      case LlmErrorType.unknown:
        return isZh ? '发生未知错误，请重试。' : 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  String toString() => 'LlmException[$type]: $message';
}
