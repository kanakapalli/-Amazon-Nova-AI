import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String> askNovaLite(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nova-lite/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response';
      } else {
        return 'Error: Studio response \${response.statusCode}';
      }
    } catch (e) {
      print('Network Error in askNovaLite: $e');
      return 'Network Error: Cannot reach Django server. Ensure it is running on $baseUrl';
    }
  }

  Future<Map<String, dynamic>> askNovaSonic(String base64Audio) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nova-sonic/audio/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'audio_data': base64Audio}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'text_reply': 'Error \${response.statusCode}',
          'audio_reply_base64': null,
        };
      }
    } catch (e) {
      print('Network Error in askNovaSonic: $e');
      return {'text_reply': 'Network Error', 'audio_reply_base64': null};
    }
  }

  Future<Map<String, dynamic>?> executeNovaActTask(
    String targetUrl,
    String prompt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nova-act/fleet/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'target_url': targetUrl, 'prompt': prompt}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Server returned \${response.statusCode}'};
      }
    } catch (e) {
      print('Network Error in executeNovaActTask: $e');
      return {'error': 'Network connection failed'};
    }
  }

  Future<Map<String, dynamic>?> generateNovaEmbeddings(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nova-embeddings/generate/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
