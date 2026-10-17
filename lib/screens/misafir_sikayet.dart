import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/line.dart';
import '../models/stop.dart';
import '../services/api_service.dart';

class MisafirSikayetSayfasi extends StatefulWidget {
  const MisafirSikayetSayfasi({super.key});

  @override
  State<MisafirSikayetSayfasi> createState() =>
      _MisafirSikayetSayfasiState();
}

class _MisafirSikayetSayfasiState extends State<MisafirSikayetSayfasi> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  final _contactFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _complaintFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _telefonIle = false;
  final _codeController = TextEditingController();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();

  int _adim = 0; // 0: iletişim yöntemi, 1: kod, 2: şikayet
  bool _islemYapiliyor = false;
  String? _hataMesaji;
  String? _verificationToken;

  List<Line> _hatlar = [];
  List<Stop> _duraklar = [];
  Line? _secilenHat;
  Stop? _secilenDurak;
  String? _secilenKategori;

  bool _hatlarYukleniyor = false;
  bool _duraklarYukleniyor = false;

  double? _latitude;
  double? _longitude;
  bool _konumAliniyor = false;
  String? _konumHatasi;

  XFile? _secilenMedya;
  String? _medyaTuru;

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
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  String _apiHatasi(http.Response response, String varsayilan) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // JSON dışı yanıt gelirse varsayılan mesaj kullanılır.
    }
    return '$varsayilan (HTTP ${response.statusCode})';
  }

  Map<String, String> _iletisimVerisi() => _telefonIle
      ? {'phone': _phoneController.text.trim()}
      : {'email': _emailController.text.trim().toLowerCase()};

  String get _iletisimDegeri => _telefonIle
      ? _phoneController.text.trim()
      : _emailController.text.trim();

  Future<void> _kodGonder() async {
    if (_islemYapiliyor || !_contactFormKey.currentState!.validate()) return;

    setState(() {
      _islemYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/guest/complaints/request-code'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_iletisimVerisi()),
      );

      if (response.statusCode != 200) {
        throw Exception(_apiHatasi(response, 'Doğrulama kodu gönderilemedi.'));
      }

      if (!mounted) return;
      setState(() {
        _adim = 1;
        _codeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_telefonIle
              ? 'Yerel test kodu Laravel log dosyasına yazıldı. SMS gönderilmedi.'
              : '6 haneli kod e-posta adresinize gönderildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  Future<void> _koduDogrula() async {
    if (_islemYapiliyor || !_codeFormKey.currentState!.validate()) return;

    setState(() {
      _islemYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/guest/complaints/verify-code'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          ..._iletisimVerisi(),
          'code': _codeController.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(_apiHatasi(response, 'Doğrulama kodu doğrulanamadı.'));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Sunucudan beklenmeyen bir yanıt alındı.');
      }

      final token = decoded['verification_token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('Doğrulama anahtarı alınamadı.');
      }

      if (!mounted) return;

      // Kod doğrulanınca kullanıcıyı hemen şikayet formuna geçiriyoruz.
      // Hat/konum yüklemelerinin bitmesini beklemek ekranı donmuş gibi gösteriyordu.
      setState(() {
        _verificationToken = token;
        _adim = 2;
        _islemYapiliyor = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama başarılı. Şikayetinizi yazabilirsiniz.'),
        ),
      );

      // Form açıldıktan sonra iki işlem de arka planda yürütülür.
      unawaited(_hatlariGetir());
      unawaited(_otomatikKonumAl());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && _islemYapiliyor) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  Future<void> _hatlariGetir() async {
    if (mounted) {
      setState(() {
        _hatlarYukleniyor = true;
      });
    }

    try {
      final hatlar = await _apiService.getLines();
      if (!mounted) return;
      setState(() {
        _hatlar = hatlar;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = 'Hatlar yüklenemedi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _hatlarYukleniyor = false;
        });
      }
    }
  }

  Future<void> _duraklariGetir(int lineId) async {
    setState(() {
      _duraklarYukleniyor = true;
      _duraklar = [];
      _secilenDurak = null;
    });

    try {
      final duraklar = await _apiService.getStops(lineId);
      if (!mounted) return;
      setState(() {
        _duraklar = duraklar;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duraklar yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _duraklarYukleniyor = false;
        });
      }
    }
  }

  Future<void> _otomatikKonumAl() async {
    if (!mounted) return;
    setState(() {
      _konumAliniyor = true;
      _konumHatasi = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisi kapalı. Telefonunuzun konumunu açın.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni verilmedi.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Konum izni kalıcı olarak kapalı. Telefon ayarlarından izin verin.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException(
          'Konum alınması uzun sürdü. Şikayetinizi konum olmadan da gönderebilirsiniz.',
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _konumHatasi = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _latitude = null;
        _longitude = null;
        _konumHatasi = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _konumAliniyor = false;
        });
      }
    }
  }

  Future<void> _fotografSec() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null || !mounted) return;
      setState(() {
        _secilenMedya = file;
        _medyaTuru = 'photo';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilemedi: $e')),
      );
    }
  }

  Future<void> _videoSec() async {
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (file == null || !mounted) return;
      setState(() {
        _secilenMedya = file;
        _medyaTuru = 'video';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video seçilemedi: $e')),
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
    if (_islemYapiliyor || !_complaintFormKey.currentState!.validate()) return;

    if (_verificationToken == null || _verificationToken!.isEmpty) {
      setState(() {
        _hataMesaji = 'Doğrulama geçersiz. Yeniden doğrulayın.';
      });
      return;
    }

    if (_secilenHat == null || _secilenKategori == null) return;

    setState(() {
      _islemYapiliyor = true;
      _hataMesaji = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/guest/complaints'),
      );

      request.headers['Accept'] = 'application/json';
      request.fields.addAll({
        'verification_token': _verificationToken!,
        'title': _baslikController.text.trim(),
        'category': _secilenKategori!,
        'description': _aciklamaController.text.trim(),
        'line_id': _secilenHat!.id.toString(),
      });

      if (_secilenDurak != null) {
        request.fields['stop_id'] = _secilenDurak!.id.toString();
      }
      if (_latitude != null) {
        request.fields['latitude'] = _latitude.toString();
      }
      if (_longitude != null) {
        request.fields['longitude'] = _longitude.toString();
      }
      if (_secilenMedya != null) {
        request.files.add(
          await http.MultipartFile.fromPath('media', _secilenMedya!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 201) {
        throw Exception(_apiHatasi(response, 'Şikayet gönderilemedi.'));
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            title: const Text('Şikayet Gönderildi'),
            content: const Text(
              'Şikayetiniz kayıt olmadan başarıyla gönderildi. '
              'Toplulukta “Misafir Kullanıcı” olarak görünecektir.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _islemYapiliyor = false;
        });
      }
    }
  }

  Widget _hataKutusu() {
    if (_hataMesaji == null || _hataMesaji!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _hataMesaji!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _adimGostergesi() {
    const titles = ['İletişim', 'Kod', 'Şikayet'];
    return Row(
      children: List.generate(titles.length, (index) {
        final aktif = index <= _adim;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: aktif
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: aktif
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(titles[index], style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    );
  }

  Widget _iletisimAdimi() {
    return Form(
      key: _contactFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kayıt olmadan şikayet göndermek için e-posta veya telefon '
            'numarasından birini seçip doğrulayın.',
          ),
          const SizedBox(height: 16),
          RadioGroup<bool>(
            groupValue: _telefonIle,
            onChanged: (value) {
              if (_islemYapiliyor) return;
              setState(() {
                _telefonIle = value ?? _telefonIle;
                _hataMesaji = null;
              });
            },
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('E-posta ile doğrula'),
                  secondary: const Icon(Icons.email_outlined),
                  value: false,
                  enabled: !_islemYapiliyor,
                ),
                RadioListTile<bool>(
                  title: const Text('Telefon ile doğrula'),
                  secondary: const Icon(Icons.phone_android_outlined),
                  value: true,
                  enabled: !_islemYapiliyor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_telefonIle) ...[
            TextFormField(
              controller: _phoneController,
              enabled: !_islemYapiliyor,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon numarası',
                hintText: '05XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final phone = (value ?? '').trim();
                if (!RegExp(r'^05[0-9]{9}$').hasMatch(phone)) {
                  return '05 ile başlayan 11 haneli numara girin.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'TEST MODU: Gerçek SMS gönderilmez. 6 haneli kod '
              'Laravel storage/logs/laravel.log dosyasına yazılır.',
              style: TextStyle(fontSize: 12),
            ),
          ] else
            TextFormField(
              controller: _emailController,
              enabled: !_islemYapiliyor,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-posta adresi',
                hintText: 'ornek@mail.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = (value ?? '').trim();
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Geçerli bir e-posta adresi girin.';
                }
                return null;
              },
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _islemYapiliyor ? null : _kodGonder,
              icon: _islemYapiliyor
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.mark_email_read_outlined),
              label: const Text('Doğrulama Kodu Gönder'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kodAdimi() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _telefonIle
                ? '$_iletisimDegeri için Laravel logundaki 6 haneli test kodunu girin (SMS gönderilmez).'
                : '$_iletisimDegeri adresine gönderilen 6 haneli kodu girin.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _codeController,
            enabled: !_islemYapiliyor,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: '6 haneli kod',
              prefixIcon: Icon(Icons.password_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                return '6 haneli doğrulama kodunu girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _islemYapiliyor ? null : _koduDogrula,
              icon: _islemYapiliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: const Text('Kodu Doğrula'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _islemYapiliyor
                ? null
                : () {
                    setState(() {
                      _adim = 0;
                      _codeController.clear();
                      _hataMesaji = null;
                    });
                  },
            child: const Text('İletişim yöntemini değiştir'),
          ),
        ],
      ),
    );
  }

  Widget _sikayetAdimi() {
    return Form(
      key: _complaintFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_iletisimDegeri doğrulandı.',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _baslikController,
            enabled: !_islemYapiliyor,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Başlık girin.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _secilenKategori,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: _kategoriler
                .map(
                  (kategori) => DropdownMenuItem<String>(
                    value: kategori,
                    child: Text(kategori),
                  ),
                )
                .toList(),
            onChanged: _islemYapiliyor
                ? null
                : (value) {
                    setState(() {
                      _secilenKategori = value;
                    });
                  },
            validator: (value) => value == null ? 'Kategori seçin.' : null,
          ),
          const SizedBox(height: 16),
          if (_hatlarYukleniyor)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<Line>(
              initialValue: _secilenHat,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Hat',
                prefixIcon: Icon(Icons.directions_bus),
                border: OutlineInputBorder(),
              ),
              items: _hatlar
                  .map(
                    (hat) => DropdownMenuItem<Line>(
                      value: hat,
                      child: Text(
                        '${hat.code} - ${hat.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _islemYapiliyor
                  ? null
                  : (hat) {
                      if (hat == null) return;
                      setState(() {
                        _secilenHat = hat;
                        _secilenDurak = null;
                      });
                      _duraklariGetir(hat.id);
                    },
              validator: (value) => value == null ? 'Hat seçin.' : null,
            ),
          const SizedBox(height: 16),
          if (_secilenHat != null) ...[
            if (_duraklarYukleniyor)
              const Center(child: CircularProgressIndicator())
            else if (_duraklar.isNotEmpty)
              DropdownButtonFormField<Stop>(
                initialValue: _secilenDurak,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Durak (isteğe bağlı)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _duraklar
                    .map(
                      (durak) => DropdownMenuItem<Stop>(
                        value: durak,
                        child: Text(
                          durak.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _islemYapiliyor
                    ? null
                    : (value) {
                        setState(() {
                          _secilenDurak = value;
                        });
                      },
              ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _aciklamaController,
            enabled: !_islemYapiliyor,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.length < 10) {
                return 'Açıklama en az 10 karakter olmalı.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (_konumAliniyor)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircularProgressIndicator(),
              title: Text('Konum alınıyor...'),
            )
          else if (_konumHatasi != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_off_outlined),
                title: const Text('Konum alınamadı'),
                subtitle: Text(_konumHatasi!),
                trailing: IconButton(
                  tooltip: 'Tekrar dene',
                  onPressed: _otomatikKonumAl,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Konum otomatik olarak alındı'),
                trailing: IconButton(
                  tooltip: 'Yenile',
                  onPressed: _otomatikKonumAl,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Fotoğraf / Video (isteğe bağlı)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _islemYapiliyor ? null : _fotografSec,
                          icon: const Icon(Icons.photo_outlined),
                          label: const Text('Fotoğraf'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _islemYapiliyor ? null : _videoSec,
                          icon: const Icon(Icons.video_library_outlined),
                          label: const Text('Video'),
                        ),
                      ),
                    ],
                  ),
                  if (_secilenMedya != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_medyaTuru == 'photo')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_secilenMedya!.path),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(Icons.play_circle_outline, size: 38),
                          ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Medya seçildi')),
                        IconButton(
                          tooltip: 'Kaldır',
                          onPressed: _islemYapiliyor ? null : _medyayiKaldir,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _islemYapiliyor ? null : _sikayetGonder,
              icon: _islemYapiliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _islemYapiliyor ? 'Gönderiliyor...' : 'Şikayeti Gönder',
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _islemYapiliyor
                ? null
                : () {
                    setState(() {
                      _adim = 0;
                      _verificationToken = null;
                      _codeController.clear();
                      _hataMesaji = null;
                    });
                  },
            child: const Text('Yeniden doğrula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Olmadan Şikayet Et'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _adimGostergesi(),
              const SizedBox(height: 24),
              _hataKutusu(),
              if (_adim == 0)
                _iletisimAdimi()
              else if (_adim == 1)
                _kodAdimi()
              else
                _sikayetAdimi(),
            ],
          ),
        ),
      ),
    );
  }
}
