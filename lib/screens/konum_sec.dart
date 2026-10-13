import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KonumSecSayfasi extends StatefulWidget {
  const KonumSecSayfasi({super.key});

  @override
  State<KonumSecSayfasi> createState() => _KonumSecSayfasiState();
}

class _KonumSecSayfasiState extends State<KonumSecSayfasi> {
  LatLng? _secilenKonum;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritadan Konum Seç'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(
                  41.6344,
                  32.3375,
                ),
                initialZoom: 13,

                // Haritada tıklanan koordinatı alıyoruz.
                onTap: (tapPosition, point) {
                  setState(() {
                    _secilenKonum = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.akilli_toplu_tasima',
                ),

                if (_secilenKonum != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _secilenKonum!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),

                const SimpleAttributionWidget(
                  source: Text(
                    'OpenStreetMap contributors',
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_secilenKonum == null)
                  const Text(
                    'Şikayetin bulunduğu noktayı haritadan seçin.',
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'Seçilen konum:\n'
                    '${_secilenKonum!.latitude.toStringAsFixed(6)}, '
                    '${_secilenKonum!.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _secilenKonum == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              _secilenKonum,
                            );
                          },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Bu Konumu Kullan',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}