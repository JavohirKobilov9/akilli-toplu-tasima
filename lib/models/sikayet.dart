class Sikayet {
  final int id;
  final String baslik;
  final String kategori;
  final String aciklama;
  final String hat;
  final String durak;
  final String durum;
  final DateTime tarih;

  Sikayet({
    required this.id,
    required this.baslik,
    required this.kategori,
    required this.aciklama,
    required this.hat,
    required this.durak,
    required this.durum,
    required this.tarih,
  });

  factory Sikayet.fromJson(Map<String, dynamic> json) {
    String hatAdi = 'Hat bilgisi yok';
    String durakAdi = 'Durak bilgisi yok';

    // Yeni sistem: line ilişkisi
    if (json['line'] is Map<String, dynamic>) {
      final line = json['line'] as Map<String, dynamic>;

      final String code = line['code'] ?? '';
      final String name = line['name'] ?? '';

      if (code.isNotEmpty && name.isNotEmpty) {
        hatAdi = '$code - $name';
      } else if (code.isNotEmpty) {
        hatAdi = code;
      }
    } else if (json['line'] is String &&
        (json['line'] as String).isNotEmpty) {
      // Eski kayıtlarla uyumluluk
      hatAdi = json['line'];
    }

    // Yeni sistem: stop ilişkisi
    if (json['stop'] is Map<String, dynamic>) {
      final stop = json['stop'] as Map<String, dynamic>;

      final String name = stop['name'] ?? '';

      if (name.isNotEmpty) {
        durakAdi = name;
      }
    } else if (json['stop'] is String &&
        (json['stop'] as String).isNotEmpty) {
      // Eski kayıtlarla uyumluluk
      durakAdi = json['stop'];
    }

    return Sikayet(
      id: json['id'] ?? 0,
      baslik: json['title'] ?? '',
      kategori: json['category'] ?? '',
      aciklama: json['description'] ?? '',
      hat: hatAdi,
      durak: durakAdi,
      durum: json['status'] ?? 'Beklemede',
      tarih: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
    };
  }
}