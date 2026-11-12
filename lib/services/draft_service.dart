import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// İnternet yokken gönderilemeyen şikayet taslağı.
class ComplaintDraft {
  final String id;
  final String baslik;
  final String kategori;
  final String aciklama;
  final int lineId;
  final int? stopId;
  final double? latitude;
  final double? longitude;
  final String? mediaPath;
  final DateTime createdAt;

  const ComplaintDraft({
    required this.id,
    required this.baslik,
    required this.kategori,
    required this.aciklama,
    required this.lineId,
    this.stopId,
    this.latitude,
    this.longitude,
    this.mediaPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'baslik': baslik,
        'kategori': kategori,
        'aciklama': aciklama,
        'lineId': lineId,
        'stopId': stopId,
        'latitude': latitude,
        'longitude': longitude,
        'mediaPath': mediaPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ComplaintDraft.fromJson(Map<String, dynamic> json) {
    return ComplaintDraft(
      id: json['id'].toString(),
      baslik: json['baslik']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      aciklama: json['aciklama']?.toString() ?? '',
      lineId: int.tryParse(json['lineId'].toString()) ?? 0,
      stopId: int.tryParse(json['stopId']?.toString() ?? ''),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      mediaPath: json['mediaPath']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

/// Taslakları cihazda (SharedPreferences) saklar.
class DraftService {
  static const _key = 'complaint_drafts';

  Future<List<ComplaintDraft>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final drafts = <ComplaintDraft>[];
    for (final item in raw) {
      try {
        drafts.add(
          ComplaintDraft.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // Bozuk kayıt atlanır.
      }
    }
    return drafts;
  }

  Future<void> save(ComplaintDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    await prefs.setStringList(_key, [...raw, jsonEncode(draft.toJson())]);
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = <String>[];
    for (final item in prefs.getStringList(_key) ?? const <String>[]) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        if (map['id'].toString() != id) kept.add(item);
      } catch (_) {
        // Bozuk kayıt temizlenir.
      }
    }
    await prefs.setStringList(_key, kept);
  }

  /// Hata internet/sunucuya erişim sorunundan mı kaynaklanıyor?
  static bool isNetworkError(Object e) {
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('TimeoutException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection refused') ||
        text.contains('Network is unreachable');
  }
}
