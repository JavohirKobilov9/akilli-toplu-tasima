import 'package:flutter/material.dart';

import '../models/line.dart';
import '../models/line_schedule.dart';
import '../services/api_service.dart';

class SeferSaatleriSayfasi extends StatefulWidget {
  const SeferSaatleriSayfasi({
    super.key,
  });

  @override
  State<SeferSaatleriSayfasi> createState() =>
      _SeferSaatleriSayfasiState();
}

class _SeferSaatleriSayfasiState
    extends State<SeferSaatleriSayfasi> {
  final ApiService _apiService = ApiService();

  List<Line> _hatlar = [];
  List<LineSchedule> _seferler = [];

  Line? _secilenHat;

  bool _hatlarYukleniyor = true;
  bool _seferlerYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _hatlariGetir();
  }

  Future<void> _hatlariGetir() async {
    try {
      final hatlar = await _apiService.getLines();

      if (!mounted) return;

      setState(() {
        _hatlar = hatlar;
        _hatlarYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hatlarYukleniyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hatlar alınamadı: $e',
          ),
        ),
      );
    }
  }

  Future<void> _seferleriGetir(
    Line hat,
  ) async {
    setState(() {
      _secilenHat = hat;
      _seferler = [];
      _seferlerYukleniyor = true;
    });

    try {
      final seferler =
          await _apiService.getSchedules(
        hat.id,
      );

      if (!mounted) return;

      setState(() {
        _seferler = seferler;
        _seferlerYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _seferlerYukleniyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sefer saatleri alınamadı: $e',
          ),
        ),
      );
    }
  }

  Map<String, List<LineSchedule>>
      _gruplandirilmisSeferler() {
    final Map<String, List<LineSchedule>>
        gruplar = {};

    for (final sefer in _seferler) {
      final yon = sefer.direction == null ||
              sefer.direction!.isEmpty
          ? 'Yön belirtilmemiş'
          : sefer.direction!;

      final anahtar =
          '${sefer.servicePeriod} - $yon';

      gruplar.putIfAbsent(
        anahtar,
        () => [],
      );

      gruplar[anahtar]!.add(sefer);
    }

    return gruplar;
  }

  @override
  Widget build(BuildContext context) {
    final gruplar =
        _gruplandirilmisSeferler();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sefer Saatleri',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Line>(
              initialValue: _secilenHat,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _hatlarYukleniyor
                    ? 'Hatlar yükleniyor...'
                    : 'Güzergah Seç',
                border:
                    const OutlineInputBorder(),
              ),
              items: _hatlar.map((hat) {
                return DropdownMenuItem<Line>(
                  value: hat,
                  child: Text(
                    '${hat.code} - ${hat.name}',
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _hatlarYukleniyor
                  ? null
                  : (hat) {
                      if (hat != null) {
                        _seferleriGetir(hat);
                      }
                    },
            ),

            const SizedBox(height: 20),

            if (_seferlerYukleniyor)
              const Expanded(
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_secilenHat == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'Sefer saatlerini görmek için '
                    'bir güzergah seçiniz.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              )
            else if (_seferler.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Bu güzergah için henüz '
                    'sefer saati verisi bulunmuyor.',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children:
                      gruplar.entries.map((entry) {
                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        children:
                            entry.value.map((sefer) {
                          return ListTile(
                            leading: const Icon(
                              Icons.schedule,
                            ),
                            title: Text(
                              sefer.departureTime,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle:
                                sefer.note != null &&
                                        sefer.note!
                                            .isNotEmpty
                                    ? Text(
                                        sefer.note!,
                                      )
                                    : null,
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}