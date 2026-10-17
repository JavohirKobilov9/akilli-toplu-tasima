
class Sikayet {
  final int id;
  final String baslik;
  final String kategori;
  final String aciklama;
  final String hat;
  final String durak;
  final String durum;
  final DateTime tarih;

  final String kullaniciAdi;

  // Yalnızca yönetici API'sinden gelen bilgiler.
  final String? kullaniciEmail;
  final String? kullaniciTelefon;
  final bool misafirMi;

  final double? latitude;
  final double? longitude;

  Sikayet({
    required this.id,
    required this.baslik,
    required this.kategori,
    required this.aciklama,
    required this.hat,
    required this.durak,
    required this.durum,
    required this.tarih,
    required this.kullaniciAdi,
    this.kullaniciEmail,
    this.kullaniciTelefon,
    this.misafirMi = false,
    this.latitude,
    this.longitude,
  });

  factory Sikayet.fromJson(
    Map<String, dynamic> json,
  ) {
    String hatAdi = 'Hat bilgisi yok';
    String durakAdi = 'Durak bilgisi yok';

    if (json['line'] is Map<String, dynamic>) {
      final line =
          json['line'] as Map<String, dynamic>;

      final code =
          line['code']?.toString() ?? '';
      final name =
          line['name']?.toString() ?? '';

      if (code.isNotEmpty && name.isNotEmpty) {
        hatAdi = '$code - $name';
      } else if (code.isNotEmpty) {
        hatAdi = code;
      }
    } else if (json['line'] is String &&
        (json['line'] as String).isNotEmpty) {
      hatAdi = json['line'];
    }

    if (json['stop'] is Map<String, dynamic>) {
      final stop =
          json['stop'] as Map<String, dynamic>;

      final name =
          stop['name']?.toString() ?? '';

      if (name.isNotEmpty) {
        durakAdi = name;
      }
    } else if (json['stop'] is String &&
        (json['stop'] as String).isNotEmpty) {
      durakAdi = json['stop'];
    }

    String? nullableText(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return Sikayet(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(
                json['id']?.toString() ?? '',
              ) ??
              0,
      baslik: json['title']?.toString() ?? '',
      kategori: json['category']?.toString() ?? '',
      aciklama: json['description']?.toString() ?? '',
      hat: hatAdi,
      durak: durakAdi,
      durum: json['status']?.toString() ?? 'Beklemede',
      tarih: json['created_at'] != null
          ? DateTime.tryParse(
                json['created_at'].toString(),
              ) ??
              DateTime.now()
          : DateTime.now(),
      kullaniciAdi:
          json['user_display_name']?.toString() ??
              'Kullanıcı',
      kullaniciEmail: nullableText(json['user_email']),
      kullaniciTelefon: nullableText(json['user_phone']),
      misafirMi: json['is_guest'] == true,
      latitude: json['latitude'] != null
          ? double.tryParse(
              json['latitude'].toString(),
            )
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(
              json['longitude'].toString(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': baslik,
      'category': kategori,
      'description': aciklama,
      'line': hat,
      'stop': durak,
      'status': durum,
      'created_at': tarih.toIso8601String(),
      'user_display_name': kullaniciAdi,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
