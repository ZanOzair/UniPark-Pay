import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GistConfig {
  static Future<Map<String, dynamic>> fetchConfig() async {
    HttpClient client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(dotenv.env['GIST_ENDPOINT']!));
      request.headers.add('Authorization', 'Bearer ${dotenv.env['GIST_TOKEN']}');
      request.headers.add('Accept', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode != 200) {
        throw Exception('Gist Error [${response.statusCode}]: $responseBody');
      }

      final json = jsonDecode(responseBody);
      final files = json['files'] as Map<String, dynamic>;
      final file = files.values.first;
      final content = file['content'] as String;
      
      return jsonDecode(content) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}