import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

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
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _secilenMedya;
  String? _medyaTuru; // photo veya video

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
  double? _latitude;
  double? _longitude;

  bool _konumAliniyor = true;
  String? _konumHatasi;

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
    _otomatikKonumAl();
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

  Future<void> _otomatikKonumAl() async {
    if (!mounted) return;

    setState(() {
      _konumAliniyor = true;
      _konumHatasi = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Konum servisi kapalı. Lütfen telefonunuzun konumunu açın.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Konum izni verilmedi. Şikayet oluşturmak için konum izni gereklidir.',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Konum izni kalıcı olarak kapatılmış. Telefon ayarlarından uygulamanın konum iznini açın.',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _konumAliniyor = false;
        _konumHatasi = null;
      });
    } catch (e) {
      if (!mounted) return;

      final mesaj = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        _latitude = null;
        _longitude = null;
        _konumAliniyor = false;
        _konumHatasi = mesaj;
      });
    }
  }

  Future<void> _fotografSecenekleriniGoster() async {
  final secim = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Fotoğraf Ekle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
              ),
              title: const Text(
                'Kameradan Çek',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                  'camera',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
              ),
              title: const Text(
                'Galeriden Seç',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                  'gallery',
                );
              },
            ),
          ],
        ),
      );
    },
  );

  if (secim == null) {
    return;
  }

  final source = secim == 'camera'
      ? ImageSource.camera
      : ImageSource.gallery;

  try {
    final fotograf =
        await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (fotograf == null || !mounted) {
      return;
    }

    setState(() {
      _secilenMedya = fotograf;
      _medyaTuru = 'photo';
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Fotoğraf seçilemedi: $e',
        ),
      ),
    );
  }
}

Future<void> _videoSecenekleriniGoster() async {
  final secim = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Video Ekle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.videocam_outlined,
              ),
              title: const Text(
                'Video Çek',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                  'camera',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.video_library_outlined,
              ),
              title: const Text(
                'Galeriden Seç',
              ),
              onTap: () {
                Navigator.pop(
                  context,
                  'gallery',
                );
              },
            ),
          ],
        ),
      );
    },
  );

  if (secim == null) {
    return;
  }

  final source = secim == 'camera'
      ? ImageSource.camera
      : ImageSource.gallery;

  try {
    final video =
        await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(
        seconds: 60,
      ),
    );

    if (video == null || !mounted) {
      return;
    }

    setState(() {
      _secilenMedya = video;
      _medyaTuru = 'video';
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Video seçilemedi: $e',
        ),
      ),
    );
  }
}

void _medyayiKaldir() {
  setState(() {
    _secilenMedya = null;
    _medyaTuru = null;
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

    if (_konumAliniyor) {
      setState(() {
        _hataMesaji =
            'Konumunuz henüz alınıyor. Lütfen birkaç saniye bekleyin.';
      });
      return;
    }

    if (_latitude == null || _longitude == null) {
      setState(() {
        _hataMesaji =
            'Konum alınamadı. Konum servisini ve uygulama iznini kontrol edip tekrar deneyin.';
      });
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
        latitude: _latitude,
        longitude: _longitude,
        mediaPath: _secilenMedya?.path,
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
                        'Telefon konumu otomatik olarak kullanılacaktır.',
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                if (_konumAliniyor)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Telefon konumunuz otomatik olarak alınıyor...',
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_konumHatasi != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _konumHatasi!,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _otomatikKonumAl,
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'Konumu Tekrar Al',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Konumunuz otomatik olarak alındı.',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Konumu yenile',
                          onPressed: _otomatikKonumAl,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // FOTOĞRAF / VİDEO EKLE
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    border: Border.all(
      color: Colors.grey.shade400,
    ),
    borderRadius:
        BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Fotoğraf veya Video Ekle',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),

      const SizedBox(height: 12),

      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _fotografSecenekleriniGoster,
              icon: const Icon(
                Icons.camera_alt_outlined,
              ),
              label: const Text(
                'Fotoğraf',
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _videoSecenekleriniGoster,
              icon: const Icon(
                Icons.videocam_outlined,
              ),
              label: const Text(
                'Video',
              ),
            ),
          ),
        ],
      ),

      if (_secilenMedya != null) ...[
        const SizedBox(height: 14),

        Container(
          padding:
              const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo
                .withValues(
              alpha: 0.06,
            ),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (_medyaTuru ==
                  'photo')
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  child: Image.file(
                    File(
                      _secilenMedya!.path,
                    ),
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 65,
                  height: 65,
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .indigo.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .play_circle_outline,
                    size: 36,
                    color: Colors.indigo,
                  ),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _medyaTuru ==
                              'photo'
                          ? 'Fotoğraf seçildi'
                          : 'Video seçildi',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _secilenMedya!.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    'Medyayı kaldır',
                onPressed:
                    _medyayiKaldir,
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
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
