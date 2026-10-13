import 'dart:convert';

import '../models/complaint_comment.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/line.dart';

import '../models/line_schedule.dart';

import '../models/sikayet.dart';

import '../models/stop.dart';

class ApiService {

  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<Map<String, dynamic>> uploadProfilePhoto(

  String filePath,

) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı.',

    );

  }

  final request = http.MultipartRequest(

    'POST',

    Uri.parse(

      '$baseUrl/profile/photo',

    ),

  );

  request.headers.addAll({

    'Accept': 'application/json',

    'Authorization': 'Bearer $token',

  });

  request.files.add(

    await http.MultipartFile.fromPath(

      'photo',

      filePath,

    ),

  );

  final streamedResponse =

      await request.send();

  final response =

      await http.Response.fromStream(

    streamedResponse,

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return data;

  }

  throw Exception(

  'HTTP Kod: ${response.statusCode}\n'

  'Cevap: ${response.body}',

   );

}

Future<void> deleteProfilePhoto() async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı.',

    );

  }

  final response = await http.delete(

    Uri.parse(

      '$baseUrl/profile/photo',

    ),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Profil fotoğrafı silinemedi.',

  );

}

  Future<Map<String, dynamic>> updateProfile({

  required String name,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception('Oturum bulunamadı.');

  }

  final response = await http.patch(

    Uri.parse('$baseUrl/profile'),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'name': name,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return data;

  }

  throw Exception(

    data['message'] ??

        'Profil güncellenemedi.',

  );

}

Future<void> requestEmailChangeCode({

  required String email,

  required String currentPassword,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception('Oturum bulunamadı.');

  }

  final response = await http.post(

    Uri.parse(

      '$baseUrl/profile/email/request-code',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'email': email,

      'current_password': currentPassword,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Doğrulama kodu gönderilemedi.',

  );

}

Future<Map<String, dynamic>> confirmEmailChange({

  required String code,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception('Oturum bulunamadı.');

  }

  final response = await http.post(

    Uri.parse(

      '$baseUrl/profile/email/confirm',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'code': code,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return data;

  }

  throw Exception(

    data['message'] ??

        'E-posta doğrulanamadı.',

  );

}

   Future<void> deleteComplaint(

  int complaintId,

) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı.',

    );

  }

  final response = await http.delete(

    Uri.parse(

      '$baseUrl/complaints/$complaintId',

    ),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Şikayet silinemedi.',

  );

}

Future<List<Sikayet>> getMyComplaints() async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı. Lütfen tekrar giriş yapın.',

    );

  }

  final response = await http.get(

    Uri.parse('$baseUrl/my-complaints'),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  if (response.statusCode == 200) {

    final Map<String, dynamic> jsonData =

        jsonDecode(response.body);

    final List<dynamic> data =

        jsonData['data'];

    return data

        .map(

          (item) => Sikayet.fromJson(

            item as Map<String, dynamic>,

          ),

        )

        .toList();

  }

  throw Exception(

    'Şikayetleriniz alınamadı.\n'

    'Kod: ${response.statusCode}\n'

    'Cevap: ${response.body}',

  );

}

  String? _token;

  Future<void> saveToken(String token) async {

    _token = token;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', token);

  }

  Future<String?> getToken() async {

    if (_token != null) {

      return _token;

    }

    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('auth_token');

    return _token;

  }

  Future<void> clearToken() async {

    _token = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');

  }

 Future<Map<String, dynamic>> login(

  String identifier,

  String password,

) async {

  final response = await http.post(

    Uri.parse('$baseUrl/login'),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

    },

    body: jsonEncode({

      'identifier': identifier,

      'password': password,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    final String token = data['token'];

    await saveToken(token);

    return data;

  }

  if (response.statusCode == 423) {

    return {

      'success': false,

      'must_reset_password': true,

      'message': data['message'] ??

          'Şifrenizi yenilemeniz gerekiyor.',

    };

  }

  throw Exception(

    data['message'] ??

        'E-posta/telefon veya şifre hatalı.',

  );

}

  Future<Map<String, dynamic>> register(

  String name,

  String? email,

  String? phone,

  String password,

) async {

  final response = await http.post(

    Uri.parse('$baseUrl/register'),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

    },

    body: jsonEncode({

      'name': name,

      'email': email,

      'phone': phone,

      'password': password,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 201) {

    final String token = data['token'];

    await saveToken(token);

    return data;

  }

  throw Exception(

    data['message'] ?? 'Kayıt oluşturulamadı.',

  );

}

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

  Future<bool> sikayetOlustur({
    required String baslik,
    required String kategori,
    required String aciklama,
    required int lineId,
    int? stopId,
    double? latitude,
    double? longitude,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': baslik,
        'category': kategori,
        'description': aciklama,
        'line_id': lineId,
        'stop_id': stopId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (response.statusCode == 201) {
      return true;
    }

    throw Exception(
      data['message'] ??
          'Şikayet gönderilemedi.',
    );
  }

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

  Future<List<LineSchedule>> getSchedules(

    int lineId,

  ) async {

    final response = await http.get(

      Uri.parse(

        '$baseUrl/lines/$lineId/schedules',

      ),

      headers: {

        'Accept': 'application/json',

      },

    );

    if (response.statusCode == 200) {

      final Map<String, dynamic> jsonData =

          jsonDecode(response.body);

      final List<dynamic> data =

          jsonData['data'];

      return data

          .map(

            (item) => LineSchedule.fromJson(

              item as Map<String, dynamic>,

            ),

          )

          .toList();

    }

    throw Exception(

      'Sefer saatleri alınamadı.\n'

      'Kod: ${response.statusCode}\n'

      'Cevap: ${response.body}',

    );

  }

  Future<List<ComplaintComment>> getComments(

  int complaintId,

) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı. Lütfen tekrar giriş yapın.',

    );

  }

  final response = await http.get(

    Uri.parse(

      '$baseUrl/complaints/$complaintId/comments',

    ),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  if (response.statusCode == 200) {

    final Map<String, dynamic> jsonData =

        jsonDecode(response.body);

    final List<dynamic> data = jsonData['data'];

    return data

        .map(

          (item) => ComplaintComment.fromJson(

            item as Map<String, dynamic>,

          ),

        )

        .toList();

  }

  throw Exception(

    'Yorumlar alınamadı.\n'

    'Kod: ${response.statusCode}\n'

    'Cevap: ${response.body}',

  );

}

Future<Map<String, dynamic>> reactToComment({

  required int commentId,

  required String reaction,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı. Lütfen tekrar giriş yapın.',

    );

  }

  final response = await http.post(

    Uri.parse(

      '$baseUrl/comments/$commentId/reaction',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'reaction': reaction,

    }),

  );

  if (response.statusCode == 200) {

    final Map<String, dynamic> jsonData =

        jsonDecode(response.body);

    return jsonData['data'];

  }

  throw Exception(

    'Oy işlemi başarısız.\n'

    'Kod: ${response.statusCode}\n'

    'Cevap: ${response.body}',

  );

}

Future<ComplaintComment> addComment({

  required int complaintId,

  required String comment,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı. Lütfen tekrar giriş yapın.',

    );

  }

  final response = await http.post(

    Uri.parse(

      '$baseUrl/complaints/$complaintId/comments',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'comment': comment,

    }),

  );

  if (response.statusCode == 201) {

    final Map<String, dynamic> jsonData =

        jsonDecode(response.body);

    return ComplaintComment.fromJson(

      jsonData['data'],

    );

  }

  throw Exception(

    'Yorum gönderilemedi.\n'

    'Kod: ${response.statusCode}\n'

    'Cevap: ${response.body}',

  );

}

Future<bool> deleteComment(

  int commentId,

) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception(

      'Oturum bulunamadı. Lütfen tekrar giriş yapın.',

    );

  }

  final response = await http.delete(

    Uri.parse(

      '$baseUrl/comments/$commentId',

    ),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  if (response.statusCode == 200) {

    return true;

  }

  throw Exception(

    'Yorum silinemedi.\n'

    'Kod: ${response.statusCode}\n'

    'Cevap: ${response.body}',

  );

}

 Future<Map<String, dynamic>> getMe() async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception('Oturum bulunamadı.');

  }

  final response = await http.get(

    Uri.parse('$baseUrl/me'),

    headers: {

      'Accept': 'application/json',

      'Authorization': 'Bearer $token',

    },

  );

  if (response.statusCode == 200) {

    final Map<String, dynamic> data =

        jsonDecode(response.body);

    return data['user'];

  }

  if (response.statusCode == 401) {

    await clearToken();

    throw Exception(

      'Oturum süresi sona ermiş.',

    );

  }

  throw Exception(

    'Kullanıcı bilgileri alınamadı.\n'

    'Kod: ${response.statusCode}',

  );

}

Future<bool> isLoggedIn() async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    return false;

  }

  try {

    await getMe();

    return true;

  } catch (_) {

    return false;

  }

}

Future<void> logout() async {

  final token = await getToken();

  if (token != null && token.isNotEmpty) {

    await http.post(

      Uri.parse('$baseUrl/logout'),

      headers: {

        'Accept': 'application/json',

        'Authorization': 'Bearer $token',

      },

    );

  }

  await clearToken();

}

Future<void> requestPasswordResetCode(

  String identifier,

) async {

  final response = await http.post(

    Uri.parse(

      '$baseUrl/forgot-password/request-code',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

    },

    body: jsonEncode({

      'identifier': identifier,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Doğrulama kodu gönderilemedi.',

  );

}

Future<void> resetPassword({

  required String identifier,

  required String code,

  required String password,

}) async {

  final response = await http.post(

    Uri.parse(

      '$baseUrl/forgot-password/reset',

    ),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

    },

    body: jsonEncode({

      'identifier': identifier,

      'code': code,

      'password': password,

      'password_confirmation': password,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Şifre yenilenemedi.',

  );

}

    Future<void> changePassword({

  required String currentPassword,

  required String newPassword,

}) async {

  final token = await getToken();

  if (token == null || token.isEmpty) {

    throw Exception('Oturum bulunamadı.');

  }

  final response = await http.post(

    Uri.parse('$baseUrl/change-password'),

    headers: {

      'Accept': 'application/json',

      'Content-Type': 'application/json',

      'Authorization': 'Bearer $token',

    },

    body: jsonEncode({

      'current_password': currentPassword,

      'password': newPassword,

      'password_confirmation': newPassword,

    }),

  );

  final Map<String, dynamic> data =

      jsonDecode(response.body);

  if (response.statusCode == 200) {

    return;

  }

  throw Exception(

    data['message'] ??

        'Şifre değiştirilemedi.',

  );

     }

}