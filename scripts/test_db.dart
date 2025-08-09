import 'package:mysql_client/mysql_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load();
  final token = env['GIST_TOKEN'];
  final endpoint = env['GIST_ENDPOINT'];
  
  final client = HttpClient();
  Map<String, dynamic>? dbConfig;
  
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
      final content = file['content'] as String?;
      
      if (content == null || content.isEmpty) {
        stderr.writeln('Error: Gist content is empty');
        exit(1);
      }

      try {
        dbConfig = jsonDecode(content) as Map<String, dynamic>;
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
  
  
  stdout.writeln('Initializing MySQL connection pool at ${dbConfig['host']}...');
  
  MySQLConnectionPool? pool;
  try {
    pool = MySQLConnectionPool(
      host: dbConfig['host'],
      port: dbConfig['port'],
      userName: dbConfig['username'],
      password: dbConfig['password'],
      databaseName: dbConfig['database'],
      maxConnections: 5,
    );

    stdout.writeln('Successfully initialized connection pool!');
    
    // List all tables in the database
    var result = await pool.execute('SHOW TABLES');
    if (result.rows.isNotEmpty) {
      stdout.writeln('Database contains ${result.rows.length} tables:');
      for (final row in result.rows) {
        final tableName = row.colAt(0);
        if (tableName != null) {
          stdout.writeln('- $tableName');
        }
      }
    } else {
      stdout.writeln('Database contains no tables');
    }

    await pool.close();
  } catch (e) {
    stderr.writeln('Error initializing MySQL connection pool: $e');
    stderr.writeln('Troubleshooting steps:');
    stderr.writeln('1. Verify MySQL server is running on ${dbConfig['host']}:${dbConfig['port']}');
    stderr.writeln('2. Check user credentials');
    stderr.writeln('3. Ensure network connectivity');
    stderr.writeln('4. Review MySQL server logs for errors');
    stderr.writeln('5. Try reducing maxConnections if connection limit reached');
  }
}
