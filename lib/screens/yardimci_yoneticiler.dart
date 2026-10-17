import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

class YardimciYoneticilerSayfasi extends StatefulWidget {
  const YardimciYoneticilerSayfasi({super.key});

  @override
  State<YardimciYoneticilerSayfasi> createState() =>
      _YardimciYoneticilerSayfasiState();
}

class _YardimciYoneticilerSayfasiState
    extends State<YardimciYoneticilerSayfasi> {
  final ApiService _apiService = ApiService();

  late Future<List<Map<String, dynamic>>> _yoneticilerFuture;
  int? _islemdekiYoneticiId;

  @override
  void initState() {
    super.initState();
    _yoneticilerFuture = _yoneticileriGetir();
  }

  Future<List<Map<String, dynamic>>> _yoneticileriGetir() async {
    final token = await _apiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Lütfen yeniden giriş yapın.');
    }

    final response = await http.get(
      Uri.parse('${_apiService.baseUrl}/super-admin/admins'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Sunucu JSON dışında bir yanıt gönderirse alttaki hata kullanılır.
    }

    if (response.statusCode == 200) {
      final items = data['data'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
      throw Exception('Yönetici listesi beklenen biçimde gelmedi.');
    }

    if (response.statusCode == 403) {
      throw Exception('Bu listeyi yalnızca süper yönetici görebilir.');
    }

    if (response.statusCode == 401) {
      throw Exception('Oturumunuz sona ermiş. Yeniden giriş yapın.');
    }

    throw Exception(
      data['message']?.toString() ??
          'Yöneticiler alınamadı (HTTP ${response.statusCode}).',
    );
  }

  Future<void> _yenile() async {
    final future = _yoneticileriGetir();
    setState(() {
      _yoneticilerFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // Hata mesajı FutureBuilder tarafından gösterilir.
    }
  }

  Future<void> _yoneticiEkle() async {
    final eklendi = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const _YardimciYoneticiEkleSayfasi(),
      ),
    );

    if (!mounted || eklendi != true) return;

    await _yenile();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yardımcı yönetici oluşturuldu.')),
    );
  }


  // Yetkisi kaldırılan kullanıcıyı veya başka bir normal kullanıcıyı admin yap.
  Future<void> _normalKullanicidanYoneticiSec() async {
    final atandi = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const _NormalKullanicidanYoneticiSecSayfasi(),
      ),
    );

    if (!mounted || atandi != true) return;

    await _yenile();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı yeniden yardımcı yönetici yapıldı.')),
    );
  }

  // Süper admin, yardımcı yöneticinin adını/e-postasını düzenler.
  Future<void> _yoneticiDuzenle(Map<String, dynamic> yonetici) async {
    final guncellendi = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _YardimciYoneticiDuzenleSayfasi(
          yonetici: yonetici,
        ),
      ),
    );

    if (!mounted || guncellendi != true) return;

    await _yenile();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yönetici bilgileri güncellendi.')),
    );
  }

  // Yetki kaldırıldığında hesap silinmez; rolü normal kullanıcı olur.
  Future<void> _yoneticiYetkisiniKaldir(Map<String, dynamic> yonetici) async {
    if (_islemdekiYoneticiId != null) return;

    final id = yonetici['id'];
    if (id is! int) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz yönetici ID bilgisi.')),
      );
      return;
    }

    final ad = yonetici['name']?.toString() ?? 'Bu yönetici';
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yöneticilik Yetkisini Kaldır'),
        content: Text(
          '$ad hesabının yöneticilik yetkisi kaldırılacak. '
          'Hesap silinmeyecek, normal kullanıcı olarak kalacak. '
          'Açık oturumları kapatılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yetkiyi Kaldır'),
          ),
        ],
      ),
    );

    if (!mounted || onay != true) return;

    setState(() => _islemdekiYoneticiId = id);
    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
      }

      final response = await http.patch(
        Uri.parse('${_apiService.baseUrl}/super-admin/admins/$id/revoke'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (response.statusCode == 200) {
        await _yenile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$ad artık normal kullanıcı. Hesabı silinmedi.'),
          ),
        );
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
      }
      if (response.statusCode == 403) {
        throw Exception('Bu işlem için süper yönetici yetkisi gerekir.');
      }
      if (response.statusCode == 404) {
        throw Exception('Yönetici bulunamadı veya yetkisi zaten kaldırılmış.');
      }

      throw Exception(
        data['message']?.toString() ??
            'Yetki kaldırılamadı (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _islemdekiYoneticiId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardımcı Yöneticiler'),
        actions: [
          IconButton(
            tooltip: 'Yönetici Ekle',
            onPressed: _yoneticiEkle,
            icon: const Icon(Icons.person_add_alt_1),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yenile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _yoneticilerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _yenile,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          final yoneticiler = snapshot.data ?? <Map<String, dynamic>>[];

          return RefreshIndicator(
            onRefresh: _yenile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Yardımcı yöneticiler (${yoneticiler.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu bölümde admin rolündeki hesapları görüntüleyebilirsiniz.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _yoneticiEkle,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Yardımcı Yönetici Ekle'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _normalKullanicidanYoneticiSec,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Normal Kullanıcıyı Yönetici Yap'),
                ),
                const SizedBox(height: 16),
                if (yoneticiler.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Henüz yardımcı yönetici bulunmuyor.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ...yoneticiler.map((yonetici) {
                  final ad = yonetici['name']?.toString() ?? 'Adsız yönetici';
                  final eposta = yonetici['email']?.toString();
                  final durum = yonetici['status']?.toString() ?? 'Bilinmiyor';
                  final id = yonetici['id']?.toString() ?? '-';

                  final islemDevamEdiyor = _islemdekiYoneticiId != null;

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.admin_panel_settings_outlined),
                          ),
                          title: Text(ad),
                          subtitle: Text(
                            '${(eposta == null || eposta.isEmpty) ? 'E-posta yok' : eposta}\n'
                            'ID: $id  •  Durum: $durum',
                          ),
                          isThreeLine: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 8,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: islemDevamEdiyor
                                    ? null
                                    : () => _yoneticiDuzenle(yonetici),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Düzenle'),
                              ),
                              TextButton.icon(
                                onPressed: islemDevamEdiyor
                                    ? null
                                    : () => _yoneticiYetkisiniKaldir(yonetici),
                                icon: const Icon(Icons.person_off_outlined),
                                label: const Text('Yetkiyi Kaldır'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Yetkisi kaldırılan kişilerin hesapları ve verileri korunur. '
                  'Yönetici rolü normal kullanıcıya dönüştürülür.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Yeni yardımcı yönetici oluşturma ekranı, aynı Dart dosyasında tutulur.
class _YardimciYoneticiEkleSayfasi extends StatefulWidget {
  const _YardimciYoneticiEkleSayfasi();

  @override
  State<_YardimciYoneticiEkleSayfasi> createState() =>
      _YardimciYoneticiEkleSayfasiState();
}

class _YardimciYoneticiEkleSayfasiState
    extends State<_YardimciYoneticiEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _epostaController = TextEditingController();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();
  final _apiService = ApiService();

  bool _kaydediliyor = false;
  bool _sifreGizli = true;
  String? _hataMesaji;

  @override
  void dispose() {
    _adController.dispose();
    _epostaController.dispose();
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor || !_formKey.currentState!.validate()) return;

    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Lütfen yeniden giriş yapın.');
      }

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/super-admin/admins'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _adController.text.trim(),
          'email': _epostaController.text.trim().toLowerCase(),
          'password': _sifreController.text,
          'password_confirmation': _sifreTekrarController.text,
        }),
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // JSON değilse HTTP durumu üzerinden hata verilir.
      }

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
      }
      if (response.statusCode == 403) {
        throw Exception('Yardımcı yönetici eklemek için süper yönetici yetkisi gerekir.');
      }

      String? validationError;
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            validationError = value.first.toString();
            break;
          }
        }
      }

      throw Exception(
        validationError ??
            data['message']?.toString() ??
            'Yönetici oluşturulamadı (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yardımcı Yönetici Ekle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yeni yönetici hesabı admin yetkisiyle oluşturulur.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _adController,
                  enabled: !_kaydediliyor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'En az 2 karakterli ad girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _epostaController,
                  enabled: !_kaydediliyor,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                      return 'Geçerli bir e-posta adresi girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sifreController,
                  enabled: !_kaydediliyor,
                  obscureText: _sifreGizli,
                  decoration: InputDecoration(
                    labelText: 'Şifre (en az 8 karakter)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                      onPressed: () {
                        setState(() => _sifreGizli = !_sifreGizli);
                      },
                      icon: Icon(
                        _sifreGizli ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final sifre = value ?? '';
                    if (sifre.length < 8) {
                      return 'Şifre en az 8 karakter olmalı.';
                    }
                    if (sifre.length > 72) {
                      return 'Şifre en fazla 72 karakter olmalı.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sifreTekrarController,
                  enabled: !_kaydediliyor,
                  obscureText: _sifreGizli,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _sifreController.text) {
                      return 'Şifreler eşleşmiyor.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_hataMesaji != null) ...[
                  Text(
                    _hataMesaji!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    icon: _kaydediliyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _kaydediliyor ? 'Kaydediliyor...' : 'Yardımcı Yönetici Oluştur',
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


// Yardımcı yöneticinin adını ve e-posta adresini düzenleme ekranı.
class _YardimciYoneticiDuzenleSayfasi extends StatefulWidget {
  const _YardimciYoneticiDuzenleSayfasi({required this.yonetici});

  final Map<String, dynamic> yonetici;

  @override
  State<_YardimciYoneticiDuzenleSayfasi> createState() =>
      _YardimciYoneticiDuzenleSayfasiState();
}

class _YardimciYoneticiDuzenleSayfasiState
    extends State<_YardimciYoneticiDuzenleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _epostaController = TextEditingController();
  final _apiService = ApiService();

  bool _kaydediliyor = false;
  String? _hataMesaji;

  @override
  void initState() {
    super.initState();
    _adController.text = widget.yonetici['name']?.toString() ?? '';
    _epostaController.text = widget.yonetici['email']?.toString() ?? '';
  }

  @override
  void dispose() {
    _adController.dispose();
    _epostaController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor || !_formKey.currentState!.validate()) return;

    final id = widget.yonetici['id'];
    if (id is! int) {
      setState(() => _hataMesaji = 'Geçersiz yönetici ID bilgisi.');
      return;
    }

    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
      }

      final response = await http.patch(
        Uri.parse('${_apiService.baseUrl}/super-admin/admins/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _adController.text.trim(),
          'email': _epostaController.text.trim().toLowerCase(),
        }),
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
      }
      if (response.statusCode == 403) {
        throw Exception('Bu işlem için süper yönetici yetkisi gerekir.');
      }
      if (response.statusCode == 404) {
        throw Exception('Yönetici bulunamadı veya yetkisi kaldırılmış.');
      }

      String? validationError;
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            validationError = value.first.toString();
            break;
          }
        }
      }

      throw Exception(
        validationError ??
            data['message']?.toString() ??
            'Yönetici güncellenemedi (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yardımcı Yöneticiyi Düzenle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bu işlem yalnızca ad ve e-posta adresini değiştirir. '
                  'Yönetici yetkisi ve mevcut şifre korunur.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _adController,
                  enabled: !_kaydediliyor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'En az 2 karakterli ad girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _epostaController,
                  enabled: !_kaydediliyor,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                      return 'Geçerli bir e-posta adresi girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_hataMesaji != null) ...[
                  Text(
                    _hataMesaji!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    icon: _kaydediliyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Kaydet'),
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


// Süper admin normal kullanıcılar arasından yardımcı yönetici seçer.
// Bu listede daha önce admin olup yetkisi kaldırılan hesaplar da bulunur.
class _NormalKullanicidanYoneticiSecSayfasi extends StatefulWidget {
  const _NormalKullanicidanYoneticiSecSayfasi();

  @override
  State<_NormalKullanicidanYoneticiSecSayfasi> createState() =>
      _NormalKullanicidanYoneticiSecSayfasiState();
}

class _NormalKullanicidanYoneticiSecSayfasiState
    extends State<_NormalKullanicidanYoneticiSecSayfasi> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _kullanicilarFuture;
  int? _islemdekiKullaniciId;

  @override
  void initState() {
    super.initState();
    _kullanicilarFuture = _kullanicilariGetir();
  }

  Future<List<Map<String, dynamic>>> _kullanicilariGetir() async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
    }

    final response = await http.get(
      Uri.parse('${_apiService.baseUrl}/super-admin/users'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (response.statusCode == 200) {
      final items = data['data'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
      throw Exception('Kullanıcı listesi beklenen biçimde gelmedi.');
    }
    if (response.statusCode == 403) {
      throw Exception('Bu işlem için süper yönetici yetkisi gerekir.');
    }
    if (response.statusCode == 401) {
      throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
    }
    throw Exception(
      data['message']?.toString() ??
          'Kullanıcılar alınamadı (HTTP ${response.statusCode}).',
    );
  }

  Future<void> _yenile() async {
    final future = _kullanicilariGetir();
    setState(() => _kullanicilarFuture = future);
    try {
      await future;
    } catch (_) {
      // Hata FutureBuilder üzerinde gösterilir.
    }
  }

  Future<void> _yoneticiYap(Map<String, dynamic> kullanici) async {
    if (_islemdekiKullaniciId != null) return;
    final id = kullanici['id'];
    if (id is! int) return;

    final ad = kullanici['name']?.toString() ?? 'Bu kullanıcı';
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yardımcı Yönetici Yap'),
        content: Text(
          '$ad hesabına yönetici yetkisi verilecek. '
          'Hesap, şifre ve şikayet kayıtları değişmeyecek. '
          'Kullanıcının tekrar giriş yapması gerekecek. Onaylıyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yönetici Yap'),
          ),
        ],
      ),
    );

    if (!mounted || onay != true) return;
    setState(() => _islemdekiKullaniciId = id);

    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
      }

      final response = await http.patch(
        Uri.parse('${_apiService.baseUrl}/super-admin/users/$id/promote'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      if (response.statusCode == 403) {
        throw Exception('Bu işlem için süper yönetici yetkisi gerekir.');
      }
      if (response.statusCode == 401) {
        throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
      }
      if (response.statusCode == 404) {
        throw Exception('Kullanıcı bulunamadı veya artık normal kullanıcı değil.');
      }

      throw Exception(
        data['message']?.toString() ??
            'Yönetici yetkisi verilemedi (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _islemdekiKullaniciId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Normal Kullanıcılardan Seç'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yenile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _kullanicilarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _yenile,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final kullanicilar = snapshot.data ?? <Map<String, dynamic>>[];

          return RefreshIndicator(
            onRefresh: _yenile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Yardımcı yöneticiliği kaldırılmış hesaplar da burada görünür. '
                  'Yalnızca aktif normal kullanıcılar listelenir.',
                ),
                const SizedBox(height: 12),
                if (kullanicilar.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Yönetici yapılabilecek aktif kullanıcı yok.'),
                    ),
                  ),
                ...kullanicilar.map((kullanici) {
                  final ad = kullanici['name']?.toString() ?? 'Adsız kullanıcı';
                  final eposta = kullanici['email']?.toString();
                  final id = kullanici['id']?.toString() ?? '-';
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(ad),
                      subtitle: Text(
                        '${(eposta == null || eposta.isEmpty) ? 'E-posta yok' : eposta} • ID: $id',
                      ),
                      trailing: FilledButton(
                        onPressed: _islemdekiKullaniciId != null
                            ? null
                            : () => _yoneticiYap(kullanici),
                        child: const Text('Yönetici Yap'),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
