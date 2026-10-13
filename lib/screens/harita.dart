import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/sikayet.dart';
import '../services/api_service.dart';

class HaritaScreen extends StatefulWidget {
  const HaritaScreen({super.key});

  @override
  State<HaritaScreen> createState() => _HaritaScreenState();
}

class _HaritaScreenState extends State<HaritaScreen> {
  final ApiService _apiService = ApiService();

  List<Sikayet> _sikayetler = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _sikayetleriGetir();
  }

  Future<void> _sikayetleriGetir() async {
    try {
      final sikayetler = await _apiService.getSikayetler();

      if (!mounted) return;

      setState(() {
        _sikayetler = sikayetler;
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

  void _sikayetDetayGoster(Sikayet sikayet) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final konumluSikayetler = _sikayetler
        .where(
          (sikayet) =>
              sikayet.latitude != null &&
              sikayet.longitude != null,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikayet Haritası'),
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _hata != null
              ? Center(
                  child: Text(
                    'Harita verileri alınamadı.\n$_hata',
                    textAlign: TextAlign.center,
                  ),
                )
              : FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(
                      41.6344,
                      32.3375,
                    ),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.akilli_toplu_tasima',
                    ),

                    MarkerLayer(
                      markers: konumluSikayetler.map((sikayet) {
                        return Marker(
                          point: LatLng(
                            sikayet.latitude!,
                            sikayet.longitude!,
                          ),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              _sikayetDetayGoster(sikayet);
                            },
                            child: const Icon(
                              Icons.location_pin,
                              size: 48,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SimpleAttributionWidget(
                      source: Text(
                        'OpenStreetMap contributors',
                      ),
                    ),
                  ],
                ),
    );
  }
}