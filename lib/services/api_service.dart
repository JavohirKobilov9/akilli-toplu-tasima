import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/line.dart';
import '../models/stop.dart';
import '../models/sikayet.dart';

class ApiService {
  final String baseUrl = 'http://192.168.1.105:8000/api';

  // Giriş - şimdilik geçici
  Future<bool> login(String email, String password) async {
    return email.isNotEmpty && password.isNotEmpty;
  }

  // Kayıt - şimdilik geçici
  Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty;
  }

  // Şikayetleri getir
  Future<List<Sikayet>> getSikayetler() async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaints'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body);

      final List<dynamic> data = jsonData['data'];

      return data
          .map(
            (item) => Sikayet.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Şikayetler alınamadı.\n'
      'Kod: ${response.statusCode}\n'
      'Cevap: ${response.body}',
    );
  }

  // Yeni şikayet oluştur
  Future<bool> sikayetOlustur({
    required String baslik,
    required String kategori,
    required String aciklama,
    required int lineId,
    required int stopId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': baslik,
        'category': kategori,
        'description': aciklama,
        'line_id': lineId,
        'stop_id': stopId,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    }

    throw Exception(
      'Şikayet gönderilemedi.\n'
      'Kod: ${response.statusCode}\n'
      'Cevap: ${response.body}',
    );
  }

  // Aktif hatları getir
  Future<List<Line>> getLines() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lines'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body);

      final List<dynamic> data = jsonData['data'];

      return data
          .map(
            (item) => Line.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Hatlar alınamadı.\n'
      'Kod: ${response.statusCode}\n'
      'Cevap: ${response.body}',
    );
  }

  // Seçilen hatta ait durakları getir
  Future<List<Stop>> getStops(int lineId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lines/$lineId/stops'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body);

      final List<dynamic> data = jsonData['data'];

      return data
          .map(
            (item) => Stop.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Duraklar alınamadı.\n'
      'Kod: ${response.statusCode}\n'
      'Cevap: ${response.body}',
    );
  }
}