import 'dart:convert';
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

  /// Send a single-turn prompt and return the assistant's reply text.
  /// Throws [LlmException] if no provider is configured or the call fails.
  Future<String> complete(String prompt, {String? systemPrompt}) async {
    final config = await _loadConfig();

    final baseUrl = (config['baseUrl'] as String?)?.trimRight().replaceAll(RegExp(r'/$'), '');
    final apiKey = config['apiKey'] as String? ?? '';
    final model = config['model'] as String? ?? 'gpt-4o';

    if (baseUrl == null || baseUrl.isEmpty) {
      throw LlmException('未配置 AI 提供商，请在设置中添加 API Key 和 Base URL。');
    }
    if (apiKey.isEmpty) {
      throw LlmException('API Key 为空，请在设置 → AI助手 中填写。');
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

    if (baseUrl == null || baseUrl.isEmpty) {
      throw LlmException('未配置 AI 提供商，请在设置中添加 API Key 和 Base URL。');
    }
    if (apiKey.isEmpty) {
      throw LlmException('API Key 为空，请在设置 → AI助手 中填写。');
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
    final url = Uri.parse('$baseUrl/chat/completions');

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
          throw LlmException('AI 返回了空响应。');
        }
        final content = choices[0]['message']['content'] as String?;
        return content ?? '';
      } else {
        debugPrint('LlmService HTTP ${response.statusCode}: ${response.body}');
        String detail = '';
        try {
          final err = jsonDecode(response.body);
          detail = err['error']?['message'] as String? ?? response.body;
        } catch (_) {
          detail = response.body;
        }
        throw LlmException('API 错误 (${response.statusCode}): $detail');
      }
    } on LlmException {
      rethrow;
    } catch (e) {
      throw LlmException('网络错误: $e');
    }
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('llm_providers');
    final selectedIdx = prefs.getInt('llm_selected_index') ?? 0;

    if (jsonStr == null) return {};

    try {
      final providers = jsonDecode(jsonStr) as List<dynamic>;
      if (providers.isEmpty) return {};
      final idx = selectedIdx.clamp(0, providers.length - 1);
      return providers[idx] as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

class LlmException implements Exception {
  final String message;
  LlmException(this.message);

  @override
  String toString() => 'LlmException: $message';
}
