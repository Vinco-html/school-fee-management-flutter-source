import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'https://school-fee-api-haue.onrender.com/api',
                ))
            .replaceAll(RegExp(r'/$'), '');

  final String baseUrl;

  Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    final response = switch (method) {
      'POST' =>
        await http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => await http.get(uri, headers: headers),
    };
    final decoded =
        _decodeResponse(response.body, response.headers['content-type']);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['error']?.toString()
          : decoded is String && decoded.trim().isNotEmpty
              ? _plainError(decoded)
              : null;
      throw ApiException(message, response.statusCode);
    }
    return decoded;
  }

  dynamic _decodeResponse(String body, String? contentType) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    if (!(contentType ?? '').toLowerCase().contains('json')) return body;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _plainError(String body) {
    final pre = RegExp(r'<pre>(.*?)</pre>', dotAll: true).firstMatch(body);
    return (pre?.group(1) ?? body).replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Future<DashboardSummary> dashboard() async => DashboardSummary.fromJson(
      await _request('/school/dashboard') as Map<String, dynamic>);

  Future<List<Student>> students({String search = ''}) async {
    final query =
        search.isEmpty ? '' : '?search=${Uri.encodeQueryComponent(search)}';
    final data = await _request('/school/students$query') as List<dynamic>;
    return data
        .map((item) => Student.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Student> addStudent(Map<String, dynamic> body) async =>
      Student.fromJson(
          await _request('/school/students', method: 'POST', body: body)
              as Map<String, dynamic>);

  Future<void> deleteStudent(int id) async {
    await _request('/school/students/$id', method: 'DELETE');
  }

  Future<List<SchoolClass>> classes() async {
    final data = await _request('/school/classes') as List<dynamic>;
    return data
        .map((item) => SchoolClass.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SchoolClass> addClass(Map<String, dynamic> body) async =>
      SchoolClass.fromJson(
          await _request('/school/classes', method: 'POST', body: body)
              as Map<String, dynamic>);

  Future<void> deleteClass(int id) async {
    await _request('/school/classes/$id', method: 'DELETE');
  }

  Future<List<Payment>> payments() async {
    final data = await _request('/school/payments') as List<dynamic>;
    return data
        .map((item) => Payment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PendingPayment>> pendingPayments() async {
    final data = await _request('/school/payments/pending') as List<dynamic>;
    return data
        .map((item) => PendingPayment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolvePendingPayment(int pendingId, int studentId) async {
    await _request('/school/payments/pending/$pendingId/resolve',
        method: 'POST', body: {'studentId': studentId});
  }

  Future<Payment> addManualPayment(Map<String, dynamic> body) async =>
      Payment.fromJson(
          await _request('/school/payments/manual', method: 'POST', body: body)
              as Map<String, dynamic>);

  Future<void> syncEquity() async {
    await _request('/school/payments/sync-equity', method: 'POST');
  }

  Future<List<Activity>> activity() async {
    final data = await _request('/school/activity') as List<dynamic>;
    return data
        .map((item) => Activity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SchoolNotification>> notifications() async {
    final data = await _request('/school/notifications') as List<dynamic>;
    return data
        .map(
            (item) => SchoolNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationsRead() async {
    await _request('/school/notifications/read-all', method: 'POST');
  }

  Future<List<Campaign>> messages() async {
    final data = await _request('/school/messages') as List<dynamic>;
    return data
        .map((item) => Campaign.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Campaign> createMessage(Map<String, dynamic> body) async =>
      Campaign.fromJson(
          await _request('/school/messages', method: 'POST', body: body)
              as Map<String, dynamic>);
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String? message;
  final int statusCode;
  @override
  String toString() => message ?? 'Request failed with status $statusCode';
}
