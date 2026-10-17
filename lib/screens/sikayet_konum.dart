import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SikayetKonumSayfasi extends StatelessWidget {
  final double latitude;
  final double longitude;

  const SikayetKonumSayfasi({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final konum = LatLng(
      latitude,
      longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet Konumu',
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: konum,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.akilli_toplu_tasima',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: konum,
                width: 52,
                height: 52,
                child: const Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
