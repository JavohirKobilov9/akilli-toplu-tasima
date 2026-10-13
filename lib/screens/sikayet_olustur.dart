import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/line.dart';
import '../models/stop.dart';
import '../services/api_service.dart';
import 'konum_sec.dart';

class SikayetOlusturSayfasi extends StatefulWidget {
  const SikayetOlusturSayfasi({super.key});

  @override
  State<SikayetOlusturSayfasi> createState() =>
      _SikayetOlusturSayfasiState();
}

class _SikayetOlusturSayfasiState
    extends State<SikayetOlusturSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _baslikController =
      TextEditingController();

  final TextEditingController _aciklamaController =
      TextEditingController();

  final ApiService _apiService = ApiService();

  String? _hataMesaji;

  List<Line> _hatlar = [];
  List<Stop> _duraklar = [];

  Line? _secilenHat;
  Stop? _secilenDurak;
  LatLng? _secilenKonum;

  String? _secilenKategori;

  bool _loading = false;
  bool _hatlarYukleniyor = true;
  bool _duraklarYukleniyor = false;

  final List<String> _kategoriler = [
    'Sefer Gecikmesi',
    'Araç Temizliği',
    'Şoför Davranışı',
    'Durak Sorunu',
    'Yoğunluk',
    'Güzergah Sorunu',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _hatlariGetir();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
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
            'Hatlar yüklenemedi: $e',
          ),
        ),
      );
    }
  }

  Future<void> _duraklariGetir(int lineId) async {
    setState(() {
      _duraklarYukleniyor = true;
      _duraklar = [];
      _secilenDurak = null;
    });

    try {
      final duraklar =
          await _apiService.getStops(lineId);

      if (!mounted) return;

      setState(() {
        _duraklar = duraklar;
        _duraklarYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _duraklarYukleniyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Duraklar yüklenemedi: $e',
          ),
        ),
      );
    }
  }

  Future<void> _konumSec() async {
    final sonuc = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const KonumSecSayfasi(),
      ),
    );

    if (sonuc == null || !mounted) {
      return;
    }

    setState(() {
      _secilenKonum = sonuc;
    });
  }

  Future<void> _sikayetGonder() async {
    setState(() {
      _hataMesaji = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_secilenHat == null ||
        _secilenKategori == null) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final basarili =
          await _apiService.sikayetOlustur(
        baslik: _baslikController.text.trim(),
        kategori: _secilenKategori!,
        aciklama:
            _aciklamaController.text.trim(),
        lineId: _secilenHat!.id,
        stopId: _secilenDurak?.id,
        latitude: _secilenKonum?.latitude,
        longitude: _secilenKonum?.longitude,
      );

      if (!mounted) return;

      if (basarili) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şikayet başarıyla oluşturuldu.',
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      final mesaj = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        _hataMesaji = mesaj;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet Oluştur',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _baslikController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Başlık',
                    border:
                        OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Başlık girin.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue:
                      _secilenKategori,
                  decoration:
                      const InputDecoration(
                    labelText: 'Kategori',
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                  items: _kategoriler
                      .map(
                        (kategori) =>
                            DropdownMenuItem<
                                String>(
                          value: kategori,
                          child:
                              Text(kategori),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _secilenKategori = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Kategori seçin.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                if (_hatlarYukleniyor)
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<Line>(
                    initialValue: _secilenHat,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(
                      labelText: 'Hat',
                      border:
                          OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.directions_bus,
                      ),
                    ),
                    items: _hatlar
                        .map(
                          (hat) =>
                              DropdownMenuItem<
                                  Line>(
                            value: hat,
                            child: Text(
                              '${hat.code} - ${hat.name}',
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (hat) {
                      if (hat == null) {
                        return;
                      }

                      setState(() {
                        _secilenHat = hat;
                        _secilenDurak = null;
                        _secilenKonum = null;
                      });

                      _duraklariGetir(hat.id);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Hat seçin.';
                      }

                      return null;
                    },
                  ),

                const SizedBox(height: 16),

                if (_secilenHat != null) ...[
                  if (_duraklarYukleniyor)
                    const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  else if (_duraklar.isNotEmpty)
                    DropdownButtonFormField<
                        Stop>(
                      initialValue:
                          _secilenDurak,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Durak / Güzergah Noktası',
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.location_on,
                        ),
                      ),
                      items: _duraklar
                          .map(
                            (durak) =>
                                DropdownMenuItem<
                                    Stop>(
                              value: durak,
                              child: Text(
                                durak.name,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _secilenDurak =
                              value;
                        });
                      },
                    )
                  else
                    Container(
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      decoration: BoxDecoration(
                      color: Colors.orange.withValues(
                      alpha: 0.1,
                     ),
                      borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Bu güzergah için durak verisi bulunmuyor. '
                        'Şikayet konumunu haritadan seçebilirsiniz.',
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _konumSec,
                  icon: const Icon(
                    Icons.map_outlined,
                  ),
                  label: Text(
                    _secilenKonum == null
                        ? 'Haritadan Konum Seç'
                        : 'Konum Seçildi '
                            '(${_secilenKonum!.latitude.toStringAsFixed(5)}, '
                            '${_secilenKonum!.longitude.toStringAsFixed(5)})',
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _aciklamaController,
                  minLines: 4,
                  maxLines: 7,
                  decoration:
                      const InputDecoration(
                    labelText: 'Açıklama',
                    alignLabelWithHint: true,
                    border:
                        OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.description,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().length <
                            10) {
                      return 'Açıklama en az 10 karakter olmalıdır.';
                    }

                    return null;
                  },
                ),

                if (_hataMesaji != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(10),
                      border: Border.all(
                        color: Colors
                            .red.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors
                              .red.shade700,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            _hataMesaji!,
                            style:
                                TextStyle(
                              color: Colors
                                  .red
                                  .shade700,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child:
                      ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : _sikayetGonder,
                    icon: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                          ),
                    label: Text(
                      _loading
                          ? 'Gönderiliyor...'
                          : 'Şikayeti Gönder',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
