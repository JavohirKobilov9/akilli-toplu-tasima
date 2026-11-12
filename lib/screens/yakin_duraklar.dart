import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

/// Konuma göre yakındaki duraklar ve o duraktan geçen hatlar.
class _YakinDurak {
  final int id;
  final String ad;
  final String ilce;
  final double lat;
  final double lon;
  final List<String> hatlar;
  final double mesafeM;

  const _YakinDurak({
    required this.id,
    required this.ad,
    required this.ilce,
    required this.lat,
    required this.lon,
    required this.hatlar,
    required this.mesafeM,
  });
}

class YakinDuraklarSayfasi extends StatefulWidget {
  const YakinDuraklarSayfasi({super.key});

  @override
  State<YakinDuraklarSayfasi> createState() => _YakinDuraklarSayfasiState();
}

class _YakinDuraklarSayfasiState extends State<YakinDuraklarSayfasi> {
  late Future<List<_YakinDurak>> _duraklar;

  @override
  void initState() {
    super.initState();
    _duraklar = _yukle();
  }

  Future<Position> _konumAl() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Konum servisi kapalı. Telefonunuzun konumunu açın.');
    }
    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied) {
      throw Exception('Yakın durakları göstermek için konum izni gerekli.');
    }
    if (izin == LocationPermission.deniedForever) {
      throw Exception(
        'Konum izni kalıcı olarak kapalı. Telefon ayarlarından açın.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<List<_YakinDurak>> _yukle() async {
    final konum = await _konumAl();

    final response = await http.get(
      Uri.parse('${ApiService().baseUrl}/stops'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Duraklar alınamadı (HTTP ${response.statusCode}).');
    }

    final data = (jsonDecode(response.body)['data'] as List<dynamic>);
    final liste = <_YakinDurak>[];

    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final lat = double.tryParse(map['latitude']?.toString() ?? '');
      final lon = double.tryParse(map['longitude']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final hatlar = <String>{
        for (final h in (map['lines'] as List<dynamic>? ?? const []))
          (h as Map<String, dynamic>)['code']?.toString() ?? '',
      }..remove('');

      liste.add(
        _YakinDurak(
          id: int.tryParse(map['id'].toString()) ?? 0,
          ad: map['name']?.toString() ?? '',
          ilce: map['district']?.toString() ?? '',
          lat: lat,
          lon: lon,
          hatlar: hatlar.toList()..sort(),
          mesafeM: Geolocator.distanceBetween(
            konum.latitude,
            konum.longitude,
            lat,
            lon,
          ),
        ),
      );
    }

    liste.sort((a, b) => a.mesafeM.compareTo(b.mesafeM));
    return liste.take(15).toList();
  }

  String _mesafe(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

  Future<void> _haritadaAc(_YakinDurak d) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${d.lat}&mlon=${d.lon}#map=18/${d.lat}/${d.lon}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakın Duraklar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _duraklar = _yukle()),
          ),
        ],
      ),
      body: FutureBuilder<List<_YakinDurak>>(
        future: _duraklar,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final duraklar = snapshot.data ?? const <_YakinDurak>[];
          if (duraklar.isEmpty) {
            return const Center(child: Text('Yakında durak bulunamadı.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: duraklar.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = duraklar[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text(d.ad),
                  subtitle: Text(
                    [
                      if (d.ilce.isNotEmpty) d.ilce,
                      if (d.hatlar.isNotEmpty) 'Hatlar: ${d.hatlar.join(', ')}',
                    ].join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _mesafe(d.mesafeM),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text('uzaklıkta', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  onTap: () => _haritadaAc(d),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
