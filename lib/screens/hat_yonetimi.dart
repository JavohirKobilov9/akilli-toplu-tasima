import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_geometry.dart';

import 'package:flutter/material.dart';

import '../services/admin_line_service.dart';

class HatYonetimiSayfasi extends StatefulWidget {
  const HatYonetimiSayfasi({super.key});
  @override
  State<HatYonetimiSayfasi> createState() => _HatYonetimiSayfasiState();
}

class _HatYonetimiSayfasiState extends State<HatYonetimiSayfasi> {
  final _api = AdminLineService();
  late Future<List<Map<String, dynamic>>> _hatlar;
  @override
  void initState() {
    super.initState();
    _hatlar = _api.list();
  }

  void _yenile() {
    setState(() {
      _hatlar = _api.list();
    });
  }

  Future<void> _ac(int id) async {
    try {
      final hat = await _api.show(id);
      if (!mounted) return;
      final saved = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => _HatDuzenle(hat: hat)));
      if (!mounted || saved != true) return;
      _yenile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hat bilgileri kaydedildi.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hat Yönetimi')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _hatlar,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                TextButton(
                  onPressed: _yenile,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          );
        }
        final hatlar = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: () async {
            _yenile();
            await _hatlar;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Hat bilgilerini ve güzergâh koordinatlarını görüntüleyip düzenleyebilirsiniz.',
              ),
              if (hatlar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Hat bulunamadı.'),
                ),
              ...hatlar.map(
                (h) => Card(
                  child: ListTile(
                    title: Text('${h['code']} — ${h['name']}'),
                    subtitle: Text('${h['transport_type']}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _ac(h['id'] as int),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _HatDuzenle extends StatefulWidget {
  const _HatDuzenle({required this.hat});
  final Map<String, dynamic> hat;
  @override
  State<_HatDuzenle> createState() => _HatDuzenleState();
}

class _HatDuzenleState extends State<_HatDuzenle> {
  final _form = GlobalKey<FormState>();
  final _api = AdminLineService();
  late final Map<String, TextEditingController> _alanlar;
  final _geometry = TextEditingController();
  Map<String, dynamic>? _preview;
  String? _geometryError;
  String _originalGeometry = '';
  bool _saving = false;

  void _onGeometryChanged() {
    setState(() {
      _preview = null;
      _geometryError = null;
    });
  }

  void _previewGeometry() {
    try {
      final parsed = RouteGeometry.parse(_geometry.text);
      setState(() {
        _preview = parsed;
        _geometryError = null;
      });
    } catch (_) {
      setState(() {
        _preview = null;
        _geometryError =
            'Geçerli LineString JSON girin: 2–5000 adet [boylam, enlem].';
      });
    }
  }

  String? _error;
  static const _labels = {
    'name': 'Hat adı',
    'transport_type': 'Ulaşım türü',
    'start_point': 'Başlangıç',
    'end_point': 'Bitiş',
  };
  @override
  void initState() {
    super.initState();
    final geometry = widget.hat['route_geometry'];
    _originalGeometry = geometry == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(geometry);
    _geometry.text = _originalGeometry;
    if (geometry != null) {
      try {
        _preview = RouteGeometry.parse(geometry);
      } catch (_) {}
    }
    _alanlar = {
      for (final key in _labels.keys)
        key: TextEditingController(text: widget.hat[key]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    _geometry.dispose();
    for (final controller in _alanlar.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_saving || !_form.currentState!.validate()) return;
    final changed = _geometry.text != _originalGeometry;
    Map<String, dynamic>? geometry;
    if (changed) {
      try {
        geometry = RouteGeometry.parse(_geometry.text);
      } catch (_) {
        _previewGeometry();
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Güzergâh kaydedilsin mi?'),
          content: Text(
            '${widget.hat['code']} güzergâhı ${(geometry!['coordinates'] as List).length} noktayla değiştirilecek. Kullanıcılar haritayı açtığında veya yenilediğinde yeni rotayı görecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.update(widget.hat['id'] as int, {
        if (changed) 'route_geometry': geometry,
        for (final entry in _alanlar.entries)
          entry.key: entry.value.text.trim().isEmpty
              ? null
              : entry.value.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  List<LatLng> get _previewPoints => (_preview!['coordinates'] as List)
      .map((p) => LatLng(p[1] as double, p[0] as double))
      .toList();

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: Text('${widget.hat['code']} — Hat Bilgileri')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Hat kodu korunur. Koordinat sırası: [boylam, enlem].'),
            for (final entry in _alanlar.entries)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: entry.value,
                  enabled: !_saving,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: _labels[entry.key],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((entry.key == 'name' ||
                            entry.key == 'transport_type') &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Bu alan zorunludur.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _geometry,
              enabled: !_saving,
              minLines: 5,
              maxLines: 10,
              onChanged: (_) => _onGeometryChanged(),
              decoration: InputDecoration(
                labelText: 'Güzergâh (GeoJSON LineString)',
                border: const OutlineInputBorder(),
                errorText: _geometryError,
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _previewGeometry,
              child: const Text('Koordinatları doğrula ve önizle'),
            ),
            if (_preview != null) ...[
              Text('${(_preview!['coordinates'] as List).length} koordinat'),
              SizedBox(
                height: 260,
                child: FlutterMap(
                  key: ValueKey(jsonEncode(_preview)),
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(_previewPoints),
                      padding: const EdgeInsets.all(24),
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.akilli_toplu_tasima',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _previewPoints,
                          color: Colors.blue,
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Text('© OpenStreetMap contributors'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _kaydet,
              child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
            ),
          ],
        ),
      ),
    ),
  );
}
