import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todo_app/models/task.dart';

class ApiClient {
  static const String baseUrl = "http://10.0.2.2:8081";

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $apiKey',
      };

  Future<void> saveTask(Task task) async {
    print("=========== SAVE TASK");
    final uri = Uri.parse('$baseUrl/tasks');
    final res =
        await http.put(uri, headers: _headers, body: jsonEncode(task.toJson()));
    _checkOk(res);
  }

  Future<void> deleteTask(String id) async {
    print("=========== DELETE TASK");
    final uri = Uri.parse('$baseUrl/tasks/$id');
    final res = await http.delete(uri, headers: _headers);
    if (res.statusCode == 404) return; // already gone server-side, fine
    _checkOk(res);
  }

  Future<List<Task>> getAll() async {
    print("=========== GET ALL");
    final uri = Uri.parse('$baseUrl/tasks');
    final res = await http.get(uri, headers: _headers);
    _checkOk(res);
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Task>> getChangesSince(DateTime? since) async {
    print("=========== GET CHANGES");
    final uri = Uri.parse('$baseUrl/tasks/changes')
        .replace(queryParameters: {'since': since?.millisecondsSinceEpoch.toString()});
    final res = await http.get(uri, headers: _headers);
    _checkOk(res);
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
