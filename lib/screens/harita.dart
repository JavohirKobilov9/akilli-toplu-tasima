import 'dart:convert';

import '../models/route_geometry.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/line.dart';
import '../models/sikayet.dart';
import '../models/stop.dart';
import '../services/api_service.dart';

class HaritaScreen extends StatefulWidget {
  const HaritaScreen({super.key});

  @override
  State<HaritaScreen> createState() => _HaritaScreenState();
}

class _HaritaScreenState extends State<HaritaScreen> {
  final ApiService _apiService = ApiService();

  List<Sikayet> _sikayetler = [];
  List<Line> _hatlar = [];
  List<Stop> _brt25Duraklari = [];

  // BRT20 - BRT25 GUZERGAHLARI
  List<LatLng> _brt25Guzergahi = [];
  List<LatLng> _brt24Guzergahi = [];
  List<LatLng> _brt23Guzergahi = [];
  List<LatLng> _brt22Guzergahi = [];
  List<LatLng> _brt21Guzergahi = [];
  List<LatLng> _brt20Guzergahi = [];

  bool _routesLoading = false;
  String? _routeNotice;
  bool _yukleniyor = true;
  bool _yogunlukGorunumu = false;

  String? _secilenKategori;
  String? _secilenHat;
  String? _hata;

  static const _brtKodlari = {
    'BRT20',
    'BRT21',
    'BRT22',
    'BRT23',
    'BRT24',
    'BRT25',
  };

  String _normalHatAdi(String ad) => ad
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll(RegExp(r'[–—−]'), '-')
      .replaceAll(RegExp(r'\s*-\s*'), '-')
      .replaceAll(RegExp(r'\s+'), ' ');

  String _hatAnahtari(String ad) {
    final temizAd = ad.trim();
    // complaint.line bir ad veya BRT kodu içerebilir.
    final kod = RegExp(
      r'^BRT\s*(20|21|22|23|24|25)(?=$|[\s:()–—-])',
      caseSensitive: false,
    ).firstMatch(temizAd);
    if (kod != null) return 'BRT${kod.group(1)}';
    final normalAd = _normalHatAdi(temizAd);
    final eslesenler = _hatlar
        .where((hat) => _normalHatAdi(hat.name) == normalAd)
        .toList();
    // Aynı isim birden fazla hatta aitse tahminde bulunma.
    if (eslesenler.length == 1) {
      final kod = eslesenler.single.code.trim().toUpperCase();
      if (_brtKodlari.contains(kod)) return kod;
    }
    // Eski/çözülemeyen adları ayrı filtre olarak koru.
    return 'ad:$normalAd';
  }

  // Her BRT hattı için ayrı pin rengi.
  static const _hatRenkleri = <String, Color>{
    'BRT01': Color(0xFFE53935),
    'BRT02': Color(0xFF1E88E5),
    'BRT03': Color(0xFF43A047),
    'BRT04': Color(0xFFFB8C00),
    'BRT05': Color(0xFF8E24AA),
    'BRT06': Color(0xFF00ACC1),
    'BRT07': Color(0xFFD81B60),
    'BRT08': Color(0xFF7CB342),
    'BRT09': Color(0xFF5E35B1),
    'BRT10': Color(0xFFF4511E),
    'BRT11': Color(0xFF00897B),
    'BRT12': Color(0xFF3949AB),
    'BRT13': Color(0xFFAFB42B),
    'BRT14': Color(0xFF6D4C41),
    'BRT15': Color(0xFF039BE5),
    'BRT16': Color(0xFFF9A825),
    'BRT17': Color(0xFFAD1457),
    'BRT18': Color(0xFF2E7D32),
    'BRT19': Color(0xFF546E7A),
    'BRT20': Color(0xFF0D47A1),
    'BRT21': Color(0xFF9E9D24),
    'BRT22': Color(0xFF00695C),
    'BRT23': Color(0xFF6A1B9A),
    'BRT24': Color(0xFFFF8A80),
    'BRT25': Color(0xFF9575CD),
    'BRT26': Color(0xFFA1887F),
  };

  // "BRT05 - ..." gibi bir metinden ya da hat adından BRT kodunu bulur.
  // (Filtre anahtarı olan _hatAnahtari yalnızca BRT20-25'i tanıdığı için
  // renk için ayrı çözümleme yapılır.)
  String? _hatKodu(String hat) {
    final m = RegExp(
      r'BRT\s*0*(\d{1,2})(?=$|[\s:()–—-])',
      caseSensitive: false,
    ).firstMatch(hat.trim());
    if (m != null) return 'BRT${m.group(1)!.padLeft(2, '0')}';
    final normalAd = _normalHatAdi(hat);
    final eslesenler = _hatlar
        .where((h) => _normalHatAdi(h.name) == normalAd)
        .toList();
    if (eslesenler.length == 1) {
      return eslesenler.single.code.trim().toUpperCase();
    }
    return null;
  }

  // Hat çözülemezse (eski/bilinmeyen ad) nötr gri kullanılır.
  Color _hatRengi(String hat) {
    final kod = _hatKodu(hat);
    return (kod == null ? null : _hatRenkleri[kod]) ?? Colors.blueGrey;
  }

  // --------------------------------------------------
  // SAYFA BASLANGICI
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();

    _sikayetleriGetir();
    _brt25DuraklariniGetir();

    _guzergahlariYenile();
  }

  // --------------------------------------------------
  // SIKAYETLERI GETIR
  // --------------------------------------------------

  Future<void> _sikayetleriGetir() async {
    try {
      final sikayetler = await _apiService.getSikayetler();

      if (!mounted) return;

      setState(() {
        _sikayetler = sikayetler;
        _hata = null;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  // --------------------------------------------------
  // BRT25 DURAKLARINI GETIR
  // --------------------------------------------------

  Future<void> _brt25DuraklariniGetir() async {
    try {
      final duraklar = await _apiService.getStops(28);

      duraklar.sort(
        (a, b) => (a.stopOrder ?? 9999).compareTo(b.stopOrder ?? 9999),
      );

      if (!mounted) return;

      setState(() {
        _brt25Duraklari = duraklar
            .where((durak) => durak.latitude != null && durak.longitude != null)
            .toList();
      });
    } catch (e) {
      debugPrint('BRT25 duraklari alinamadi: $e');
    }
  }

  // --------------------------------------------------
  // JSON DOSYASINDAN GUZERGAH OKU
  // --------------------------------------------------

  Future<List<LatLng>> _guzergahDosyasiOku(String dosyaYolu) async {
    final jsonMetni = await rootBundle.loadString(dosyaYolu);

    // UTF-8 BOM varsa temizle
    final temizMetin = jsonMetni.startsWith('\uFEFF')
        ? jsonMetni.substring(1)
        : jsonMetni;

    final veri = jsonDecode(temizMetin) as Map<String, dynamic>;

    final koordinatlar = veri['coordinates'] as List<dynamic>;

    return koordinatlar.map((koordinat) {
      final liste = koordinat as List<dynamic>;

      // GeoJSON: [boylam, enlem]
      // Flutter: LatLng(enlem, boylam)

      return LatLng((liste[1] as num).toDouble(), (liste[0] as num).toDouble());
    }).toList();
  }

  Future<void> _guzergahlariYenile() async {
    if (_routesLoading) return;
    setState(() {
      _routesLoading = true;
    });
    final routes = <String, List<LatLng>>{};
    var fallback = false;
    List<Line>? lines;
    try {
      lines = await _apiService.getLines().timeout(const Duration(seconds: 15));
    } catch (_) {
      fallback = true;
    }
    for (final code in _brtKodlari) {
      final matching = lines
          ?.where((line) => line.code.trim().toUpperCase() == code)
          .toList();
      // A successful API response is authoritative, including inactive/absent lines.
      if (lines != null && (matching == null || matching.isEmpty)) {
        routes[code] = [];
        continue;
      }
      try {
        final geometry = RouteGeometry.parse(matching?.single.routeGeometry);
        routes[code] = (geometry['coordinates'] as List)
            .map((p) => LatLng(p[1] as double, p[0] as double))
            .toList();
      } catch (_) {
        fallback = true;
        try {
          routes[code] = await _guzergahDosyasiOku(
            'assets/routes/${code.toLowerCase()}.json',
          );
        } catch (_) {
          routes[code] = [];
        }
      }
    }
    if (!mounted) return;
    setState(() {
      if (lines != null) _hatlar = lines;
      _brt20Guzergahi = routes['BRT20']!;
      _brt21Guzergahi = routes['BRT21']!;
      _brt22Guzergahi = routes['BRT22']!;
      _brt23Guzergahi = routes['BRT23']!;
      _brt24Guzergahi = routes['BRT24']!;
      _brt25Guzergahi = routes['BRT25']!;
      _routesLoading = false;
      _routeNotice = fallback
          ? 'Bazı güzergâhlar güncel alınamadı; yerel yedek kullanılıyor.'
          : null;
    });
    if (_routeNotice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_routeNotice!)));
    }
  }

  // --------------------------------------------------
  // DURAK DETAYI
  // --------------------------------------------------

  void _durakDetayGoster(Stop durak) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BRT25 - Diş Hastanesi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  durak.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Durak sırası: ${durak.stopOrder ?? '-'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // SIKAYET DETAYI
  // --------------------------------------------------

  void _sikayetDetayGoster(Sikayet sikayet) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sikayet.sentetikMi || sikayet.misafirMi
                      ? 'Misafir Kullanıcı'
                      : sikayet.kullaniciAdi,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sikayet.baslik,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Kategori: ${sikayet.kategori}'),
                Text('Hat: ${sikayet.hat}'),
                Text('Durak: ${sikayet.durak}'),
                Text('Durum: ${sikayet.durum}'),
                const SizedBox(height: 12),
                Text(sikayet.aciklama),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // YOGUNLUK DAIRELERI
  // --------------------------------------------------

  List<CircleMarker> _yogunlukDaireleri(List<Sikayet> sikayetler) {
    const double hucreBoyutu = 0.01;

    final gruplar = <String, List<Sikayet>>{};

    for (final sikayet in sikayetler) {
      if (sikayet.latitude == null || sikayet.longitude == null) {
        continue;
      }

      final enlemHucre = (sikayet.latitude! / hucreBoyutu).floor();

      final boylamHucre = (sikayet.longitude! / hucreBoyutu).floor();

      final anahtar = '$enlemHucre:$boylamHucre';

      gruplar.putIfAbsent(anahtar, () => <Sikayet>[]).add(sikayet);
    }

    return gruplar.values.map((grup) {
      final adet = grup.length;

      final ortalamaEnlem =
          grup.map((s) => s.latitude!).reduce((a, b) => a + b) / adet;

      final ortalamaBoylam =
          grup.map((s) => s.longitude!).reduce((a, b) => a + b) / adet;

      final Color renk;

      if (adet >= 6) {
        renk = Colors.red;
      } else if (adet >= 3) {
        renk = Colors.orange;
      } else {
        renk = Colors.green;
      }

      return CircleMarker(
        point: LatLng(ortalamaEnlem, ortalamaBoylam),
        radius: 22.0 + adet * 4.0,
        useRadiusInMeter: false,
        color: renk.withValues(alpha: 0.35),
        borderColor: renk,
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  // --------------------------------------------------
  // HARITA ACIKLAMASI
  // --------------------------------------------------

  Widget _haritaAciklamasi() {
    if (_yogunlukGorunumu) {
      return const Padding(
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text('1-2', style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.circle, color: Colors.orange, size: 14),
            SizedBox(width: 4),
            Text('3-5', style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.circle, color: Colors.red, size: 14),
            SizedBox(width: 4),
            Text('6+', style: TextStyle(fontSize: 12)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Şikayet / bölge',
                style: TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final e in _hatRenkleri.entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: e.value, size: 20),
                const SizedBox(width: 2),
                Text(e.key, style: const TextStyle(fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // HARITA EKRANI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // KATEGORI LISTESI
    final kategoriler =
        _sikayetler
            .map((sikayet) => sikayet.kategori)
            .where((kategori) => kategori.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final hatEtiketleri = <String, String>{
      for (final hat in _hatlar)
        _hatAnahtari('${hat.code} - ${hat.name}'): '${hat.code} - ${hat.name}',
    };
    for (final sikayet in _sikayetler) {
      final ad = sikayet.hat.trim();
      if (ad.isEmpty || ad == 'Hat bilgisi yok') continue;
      hatEtiketleri.putIfAbsent(_hatAnahtari(ad), () => ad);
    }
    int? hatNumarasi(String etiket) {
      final eslesme = RegExp(
        r'\bBRT\s*(\d+)\b',
        caseSensitive: false,
      ).firstMatch(etiket);

      return int.tryParse(eslesme?.group(1) ?? '');
    }

    final hatlar = hatEtiketleri.keys.toList()
      ..sort((a, b) {
        final adA = hatEtiketleri[a]!;
        final adB = hatEtiketleri[b]!;
        final noA = hatNumarasi(adA);
        final noB = hatNumarasi(adB);

        if (noA != null && noB != null) {
          final sonuc = noA.compareTo(noB);
          if (sonuc != 0) return sonuc;
        } else if (noA != null) {
          return -1;
        } else if (noB != null) {
          return 1;
        }

        return adA.toLowerCase().compareTo(adB.toLowerCase());
      });

    // FILTRELENMIS SIKAYETLER
    final konumluSikayetler = _sikayetler.where((sikayet) {
      final konumuVar = sikayet.latitude != null && sikayet.longitude != null;

      final kategoriUygun =
          _secilenKategori == null || sikayet.kategori == _secilenKategori;

      final hatUygun =
          _secilenHat == null || _hatAnahtari(sikayet.hat) == _secilenHat;

      return konumuVar && kategoriUygun && hatUygun;
    }).toList();

    final gosterilenSikayetSayisi = konumluSikayetler.length;

    final seciliGuzergah = switch (_secilenHat) {
      'BRT20' => _brt20Guzergahi,
      'BRT21' => _brt21Guzergahi,
      'BRT22' => _brt22Guzergahi,
      'BRT23' => _brt23Guzergahi,
      'BRT24' => _brt24Guzergahi,
      'BRT25' => _brt25Guzergahi,
      _ => <LatLng>[],
    };
    final maviCizgiler = <Polyline>[
      if (seciliGuzergah.length >= 2)
        Polyline(
          points: seciliGuzergah,
          strokeWidth: 6,
          color: _hatRengi(_secilenHat ?? ''),
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Harita ($gosterilenSikayetSayisi)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: _routeNotice ?? 'Güzergâhları API’den yenile',
            onPressed: _routesLoading ? null : _guzergahlariYenile,
            icon: Icon(_routeNotice == null ? Icons.refresh : Icons.cloud_off),
          ),
          // HAT FILTRESI
          PopupMenuButton<String>(
            tooltip: 'Hat filtrele',
            icon: const Icon(Icons.directions_bus),
            onSelected: (hat) {
              setState(() {
                _secilenHat = hat == '__tum__' ? null : hat;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: '__tum__',
                child: Text('Tüm Hatlar'),
              ),
              ...hatlar.map(
                (hat) => PopupMenuItem<String>(
                  value: hat,
                  child: Text(
                    hatEtiketleri[hat]!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          // KATEGORI FILTRESI
          PopupMenuButton<String>(
            tooltip: 'Kategori filtrele',
            icon: const Icon(Icons.filter_list),
            onSelected: (kategori) {
              setState(() {
                _secilenKategori = kategori == '__tum__' ? null : kategori;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: '__tum__',
                child: Text('Tüm Kategoriler'),
              ),
              ...kategoriler.map(
                (kategori) => PopupMenuItem<String>(
                  value: kategori,
                  child: Text(kategori),
                ),
              ),
            ],
          ),

          // NOKTA / YOGUNLUK GORUNUMU
          IconButton(
            tooltip: _yogunlukGorunumu
                ? 'Nokta görünümüne geç'
                : 'Yoğunluk görünümüne geç',
            icon: Icon(_yogunlukGorunumu ? Icons.location_on : Icons.blur_on),
            onPressed: () {
              setState(() {
                _yogunlukGorunumu = !_yogunlukGorunumu;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: _haritaAciklamasi(),
        ),
      ),

      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
          ? Center(
              child: Text(
                'Harita verileri alınamadı.\n$_hata',
                textAlign: TextAlign.center,
              ),
            )
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(41.6344, 32.3375),
                initialZoom: 13,
              ),
              children: [
                // --------------------------------
                // OPENSTREETMAP ALTLIK
                // --------------------------------

                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.akilli_toplu_tasima',
                ),

                // --------------------------------
                // BRT20 - BRT25 MAVI GUZERGAHLAR
                // --------------------------------
                if (maviCizgiler.isNotEmpty)
                  PolylineLayer(polylines: maviCizgiler),

                // --------------------------------
                // YOGUNLUK GORUNUMU
                // --------------------------------
                if (_yogunlukGorunumu)
                  CircleLayer(circles: _yogunlukDaireleri(konumluSikayetler)),

                // --------------------------------
                // KIRMIZI SIKAYET PINLERI
                // --------------------------------
                if (!_yogunlukGorunumu)
                  MarkerLayer(
                    markers: konumluSikayetler.map((sikayet) {
                      return Marker(
                        point: LatLng(sikayet.latitude!, sikayet.longitude!),
                        width: 28,
                        height: 28,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () {
                            _sikayetDetayGoster(sikayet);
                          },
                          child: Icon(
                            Icons.location_pin,
                            size: 28,
                            color: _hatRengi(sikayet.hat),
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 3),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // --------------------------------
                // BRT25 DURAK ISARETLERI
                // --------------------------------
                if (_secilenHat == 'BRT25')
                  MarkerLayer(
                    markers: _brt25Duraklari.map((durak) {
                      return Marker(
                        point: LatLng(durak.latitude!, durak.longitude!),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () {
                            _durakDetayGoster(durak);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
    );
  }
}
