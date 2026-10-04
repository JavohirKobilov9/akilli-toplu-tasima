import 'package:flutter/material.dart';

import '../models/line.dart';
import '../models/stop.dart';
import '../services/api_service.dart';

class SikayetOlusturSayfasi extends StatefulWidget {
  const SikayetOlusturSayfasi({super.key});

  @override
  State<SikayetOlusturSayfasi> createState() =>
      _SikayetOlusturSayfasiState();
}

class _SikayetOlusturSayfasiState
    extends State<SikayetOlusturSayfasi> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();

  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();

  String? _kategori;
  Line? _secilenHat;
  Stop? _secilenDurak;

  List<Line> _hatlar = [];
  List<Stop> _duraklar = [];

  bool _hatlarYukleniyor = true;
  bool _duraklarYukleniyor = false;
  bool _gonderiliyor = false;

  final List<String> kategoriler = [
    'Gecikme',
    'Temizlik',
    'Sürücü Davranışı',
    'Yoğunluk',
    'Durak Sorunu',
    'Araç Sorunu',
    'Diğer',
  ];

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
          content: Text('Hatlar alınamadı: $e'),
        ),
      );
    }
  }

  Future<void> _duraklariGetir(Line hat) async {
    setState(() {
      _secilenHat = hat;
      _secilenDurak = null;
      _duraklar = [];
      _duraklarYukleniyor = true;
    });

    try {
      final duraklar = await _apiService.getStops(hat.id);

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
          content: Text('Duraklar alınamadı: $e'),
        ),
      );
    }
  }

  Future<void> _sikayetGonder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_kategori == null ||
        _secilenHat == null ||
        _secilenDurak == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen kategori, hat ve durak seçiniz.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _gonderiliyor = true;
    });

    try {
      final basarili = await _apiService.sikayetOlustur(
  baslik: _baslikController.text.trim(),
  kategori: _kategori!,
  aciklama: _aciklamaController.text.trim(),
  lineId: _secilenHat!.id,
  stopId: _secilenDurak!.id,
);

      if (!mounted) return;

      if (basarili) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şikayet başarıyla gönderildi.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şikayet gönderilemedi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bağlantı hatası: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gonderiliyor = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet Oluştur',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _baslikController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık giriniz.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: kategoriler.map((kategori) {
                  return DropdownMenuItem<String>(
                    value: kategori,
                    child: Text(kategori),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _kategori = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<Line>(
                initialValue: _secilenHat,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _hatlarYukleniyor
                      ? 'Hatlar yükleniyor...'
                      : 'Hat',
                  border: const OutlineInputBorder(),
                ),
                items: _hatlar.map((hat) {
                  return DropdownMenuItem<Line>(
                    value: hat,
                    child: Text(
                      '${hat.code} - ${hat.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _hatlarYukleniyor
                    ? null
                    : (hat) {
                        if (hat != null) {
                          _duraklariGetir(hat);
                        }
                      },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<Stop>(
                initialValue: _secilenDurak,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _duraklarYukleniyor
                      ? 'Duraklar yükleniyor...'
                      : 'Durak',
                  border: const OutlineInputBorder(),
                ),
                items: _duraklar.map((durak) {
                  return DropdownMenuItem<Stop>(
                    value: durak,
                    child: Text(
                      durak.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged:
                    _secilenHat == null || _duraklarYukleniyor
                    ? null
                    : (durak) {
                        setState(() {
                          _secilenDurak = durak;
                        });
                      },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _aciklamaController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText:
                      'Şikayetinizi detaylı olarak yazınız...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Açıklama en az 10 karakter olmalıdır.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _gonderiliyor ? null : _sikayetGonder,
                  child: _gonderiliyor
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Text(
                          'Şikayeti Gönder',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}