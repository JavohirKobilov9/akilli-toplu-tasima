import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AdminLineService {
  final ApiService _api = ApiService();

  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) throw Exception('Lütfen giriş yapın.');
    final uri = Uri.parse('${_api.baseUrl}/admin/lines$path');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = body == null
        ? await http.get(uri, headers: headers)
        : await http.put(uri, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 401) {
      throw Exception('Oturum sona erdi. Tekrar giriş yapın.');
    }
    if (response.statusCode == 403) {
      throw Exception('Yönetici yetkisi gerekiyor.');
    }
    if (response.statusCode == 404) {
      throw Exception('Hat bulunamadı. Listeyi yenileyin.');
    }
    if (response.statusCode != 200) {
      if (response.statusCode == 422) {
        final errors =
            (jsonDecode(response.body) as Map<String, dynamic>)['errors'];
        if (errors is Map && errors.isNotEmpty) {
          throw Exception((errors.values.first as List).first);
        }
      }
      throw Exception('İşlem tamamlanamadı. Tekrar deneyin.');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['data'];
  }

  Future<List<Map<String, dynamic>>> list() async =>
      (await _request('') as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  Future<Map<String, dynamic>> show(int id) async =>
      Map<String, dynamic>.from(await _request('/$id') as Map);
  Future<void> update(int id, Map<String, dynamic> body) async {
    await _request('/$id', body: body);
  }
}
