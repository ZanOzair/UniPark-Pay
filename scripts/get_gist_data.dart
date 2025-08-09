import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();
  final token = env['GIST_TOKEN'];
  final endpoint = env['GIST_ENDPOINT'];
  
  final client = HttpClient();
  String? content;
  
  try {
    final request = await client.getUrl(Uri.parse('$endpoint'));
    request.headers.add('Authorization', 'Bearer $token');
    request.headers.add('Accept', 'application/json');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode != 200) {
      stderr.writeln('Gist Error [${response.statusCode}]: $responseBody');
      exit(1);
    }

    try {
      final json = jsonDecode(responseBody);
      if (json['files'] == null) {
        stderr.writeln('Error: Gist response missing "files" field');
        stderr.writeln('Full response: $responseBody');
        exit(1);
      }

      final files = json['files'] as Map<String, dynamic>;
      if (files.isEmpty) {
        stderr.writeln('Error: Gist contains no files');
        exit(1);
      }

      final file = files.values.first;
      content = file['content'] as String?;
      
      if (content == null || content.isEmpty) {
        stderr.writeln('Error: Gist content is empty');
        exit(1);
      }

      try {
        jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        stderr.writeln('Error parsing Gist content as JSON: $e');
        stderr.writeln('Content: $content');
        exit(1);
      }
    } catch (e) {
      stderr.writeln('Error parsing Gist response: $e');
      stderr.writeln('Response: $responseBody');
      exit(1);
    }
  } catch (e) {
    stderr.writeln('Error fetching Gist: $e');
    exit(1);
  } finally {
    client.close();
  }
  
  stdout.writeln('Gist Configuration: $content');
}
