import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';
import 'gist_config.dart';

class DatabaseManager {
  static late DatabaseManager _instance;
  static const Duration _timeoutDuration = Duration(seconds: 10);
  late final MySQLConnectionPool _pool;

  // Private constructor
  DatabaseManager._constructor();

  // Gets the singleton instance
  factory DatabaseManager() => _instance;

  // Factory constructor to create new pool
  factory DatabaseManager.init({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String databaseName,
    int maxConnections = 5,
  }) {
    _instance = DatabaseManager._constructor();
    _instance._pool = MySQLConnectionPool(
      host: host,
      port: port,
      userName: userName,
      password: password,
      databaseName: databaseName,
      maxConnections: maxConnections,
    );
    return _instance;
  }

  Future<List<Map<String, dynamic>>> execute(
    String sql, [
    Map<String, dynamic>? params = const {},
  ]) async {
    return _handleError(
      () async {
        final result = await _pool.execute(sql, params);
        return result.rows.map((row) => row.assoc()).toList();
      },
    );
  }

  Future<List<Map<String, dynamic>>> executePrepared(
    String sql, [
    List<dynamic> params = const [],
  ]) async {
    return _handleError(
      () async {
        final stmt = await _pool.prepare(sql);
        final result = await stmt.execute(params);
        return result.rows.map((row) => row.assoc()).toList();
      },
    );
  }

  Future<void> transactional(Future<void> Function(MySQLConnection conn) callback) async {
    return _handleError(() async {
      return await _pool.transactional(callback);
    });
  }

  Future<void> close() async {
    return _handleError(() async {
      return await _pool.close();
    });
  }

  Future<T> _handleError<T>(Future<T> Function() operation) async {
    int retries = 0;
    dynamic error;
    while (retries < 2) {
      try {
        return await Future(() async => await operation()).timeout(_timeoutDuration);
      } catch (e) {
        error = e;
        retries++;
        debugPrint("Retrying operation... ($retries)");
        
        // Refresh config and reconnect
        final conf = await GistConfig.fetchConfig();
        DatabaseManager.init(
          host: conf['host'],
          port: conf['port'],
          userName: conf['username'],
          password: conf['password'],
          databaseName: conf['database'],
        );
      }
    }
    throw Exception('Operation failed after retries: $error');
  }
}
