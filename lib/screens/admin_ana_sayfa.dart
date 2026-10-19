import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/sikayet.dart';
import '../services/api_service.dart';
import '../widgets/complaint_media.dart';
import 'sikayet_konum.dart';
import 'yardimci_yoneticiler.dart';

class AdminAnaSayfa extends StatefulWidget {
  const AdminAnaSayfa({super.key});

  @override
  State<AdminAnaSayfa> createState() => _AdminAnaSayfaState();
}

class _AdminAnaSayfaState extends State<AdminAnaSayfa> {
  final ApiService _apiService = ApiService();

  late Future<List<Sikayet>> _sikayetlerFuture;
  String _rol = 'admin';
  String _kullaniciAdi = '';
  bool _cikisYapiliyor = false;

  // Hem admin hem de super_admin bu durum filtrelerini kullanabilir.
  static const List<String> _durumFiltreleri = [
    'Tümü',
    'Beklemede',
    'İnceleniyor',
    'Çözüldü',
  ];
  String _secilenFiltre = 'Tümü';

  @override
  void initState() {
    super.initState();
    _sikayetlerFuture = _verileriGetir();
  }

  Future<List<Sikayet>> _verileriGetir() async {
    final kullanici = await _apiService.getMe();
    final rol = kullanici['role']?.toString() ?? 'user';

    // Bu ekranın istemci korumasıdır.
    // Asıl güvenlik Laravel API'deki admin middleware'idir.
    if (rol != 'admin' && rol != 'super_admin') {
      throw Exception('Bu sayfa için yönetici yetkisi gerekiyor.');
    }

    _rol = rol;
    _kullaniciAdi = kullanici['name']?.toString() ?? '';
    return _apiService.getAdminSikayetler();
  }

  void _yenile() {
    setState(() {
      _sikayetlerFuture = _verileriGetir();
    });
  }

  Future<void> _profiliAc() async {
    await Navigator.pushNamed(context, '/profil');

    if (!mounted) return;
    // Profilde ad değiştirilmişse panelde de güncel adı göster.
    _yenile();
  }

  // Yardımcı yöneticiler yalnızca süper yöneticiye gösterilir.
  Future<void> _yardimciYoneticileriAc() async {
    if (_rol != 'super_admin') return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const YardimciYoneticilerSayfasi(),
      ),
    );
  }

  // Şikayet detayından durum güncellenirse listeyi ve sayaçları yenile.
  Future<void> _sikayetDetayiniAc(Sikayet sikayet) async {
    final guncellendi = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _AdminSikayetDetaySayfasi(
          sikayet: sikayet,
        ),
      ),
    );

    if (!mounted || guncellendi != true) return;

    _yenile();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Şikayet durumu güncellendi.')),
    );
  }

  Future<void> _cikisYap() async {
    if (_cikisYapiliyor) return;

    setState(() {
      _cikisYapiliyor = true;
    });

    try {
      await _apiService.logout();
    } catch (_) {
      // Sunucu geçici olarak erişilemezse yerel oturumu kapat.
      await _apiService.clearToken();
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/giris',
      (route) => false,
    );
  }

  Widget _sayac(String etiket, int sayi) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Text(
                '$sayi',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                etiket,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: _profiliAc,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yenile,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            onPressed: _cikisYapiliyor ? null : _cikisYap,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Sikayet>>(
        future: _sikayetlerFuture,
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
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _yenile,
                      child: const Text('Yeniden Dene'),
                    ),
                    TextButton(
                      onPressed: _cikisYapiliyor ? null : _cikisYap,
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              ),
            );
          }

          final sikayetler = snapshot.data ?? <Sikayet>[];
          final bekleyen = sikayetler
              .where((sikayet) => sikayet.durum == 'Beklemede')
              .length;
          final incelenen = sikayetler
              .where((sikayet) => sikayet.durum == 'İnceleniyor')
              .length;
          final cozulmus = sikayetler
              .where((sikayet) => sikayet.durum == 'Çözüldü')
              .length;
          final filtrelenmisSikayetler = _secilenFiltre == 'Tümü'
              ? sikayetler
              : sikayetler
                  .where((sikayet) => sikayet.durum == _secilenFiltre)
                  .toList();

          return RefreshIndicator(
            onRefresh: () async {
              _yenile();
              await _sikayetlerFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(
                    _rol == 'super_admin'
                        ? 'Süper Yönetici'
                        : 'Yönetici',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_kullaniciAdi.trim().isNotEmpty)
                        Text(_kullaniciAdi),
                      const Text('Bartın toplu taşıma şikayetleri'),
                    ],
                  ),
                ),
                if (_rol == 'super_admin') ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.supervisor_account_outlined,
                      ),
                      title: const Text('Yardımcı Yöneticiler'),
                      subtitle: const Text(
                        'Admin hesaplarını ve durumlarını görüntüle',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _yardimciYoneticileriAc,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _sayac('Beklemede', bekleyen),
                    _sayac('İnceleniyor', incelenen),
                    _sayac('Çözüldü', cozulmus),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Şikayetler (${filtrelenmisSikayetler.length}/${sikayetler.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                // Küçük telefon ekranlarında sekmeler yatay kaydırılabilir.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _durumFiltreleri.map((durum) {
                      final secili = _secilenFiltre == durum;
                      final sayi = switch (durum) {
                        'Beklemede' => bekleyen,
                        'İnceleniyor' => incelenen,
                        'Çözüldü' => cozulmus,
                        _ => sikayetler.length,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$durum ($sayi)'),
                          selected: secili,
                          onSelected: (_) {
                            setState(() {
                              _secilenFiltre = durum;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                if (filtrelenmisSikayetler.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _secilenFiltre == 'Tümü'
                          ? 'Henüz şikayet bulunmuyor.'
                          : '$_secilenFiltre durumunda şikayet bulunmuyor.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...filtrelenmisSikayetler.map(
                  (sikayet) => Card(
                    child: ListTile(
                      title: Text(sikayet.baslik),
                      subtitle: Text(
                        '${sikayet.hat}\n'
                        '${sikayet.kategori} • ${sikayet.durum}',
                      ),
                      isThreeLine: true,
                      leading: const Icon(Icons.assignment_outlined),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _sikayetDetayiniAc(sikayet),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kullanıcıyla özel mesajlaşma ve gelişmiş analizler '
                  'sonraki adımlarda eklenecek.',
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


// Şikayet detay ve durum düzenleme ekranı.
// Ayrı bir route veya başka dosya değiştirmek gerekmez.
class _AdminSikayetDetaySayfasi extends StatefulWidget {
  const _AdminSikayetDetaySayfasi({required this.sikayet});

  final Sikayet sikayet;

  @override
  State<_AdminSikayetDetaySayfasi> createState() =>
      _AdminSikayetDetaySayfasiState();
}

class _AdminSikayetDetaySayfasiState
    extends State<_AdminSikayetDetaySayfasi> {
  final ApiService _apiService = ApiService();
  static const List<String> _durumlar = [
    'Beklemede',
    'İnceleniyor',
    'Çözüldü',
  ];

  late String _secilenDurum;
  bool _kaydediliyor = false;
  String? _hataMesaji;

  @override
  void initState() {
    super.initState();
    _secilenDurum = _durumlar.contains(widget.sikayet.durum)
        ? widget.sikayet.durum
        : 'Beklemede';
  }

  String _tarihMetni(DateTime tarih) {
    final yerel = tarih.toLocal();
    String iki(int sayi) => sayi.toString().padLeft(2, '0');

    return '${iki(yerel.day)}.${iki(yerel.month)}.${yerel.year} '
        '${iki(yerel.hour)}:${iki(yerel.minute)}';
  }

  Future<void> _durumuKaydet() async {
    if (_kaydediliyor) return;

    if (_secilenDurum == widget.sikayet.durum) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final response = await http.patch(
        Uri.parse(
          '${_apiService.baseUrl}/complaints/${widget.sikayet.id}/status',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': _secilenDurum}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }

      String? sunucuMesaji;
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          sunucuMesaji = data['message']?.toString();
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final ilk = errors.values.first;
            if (ilk is List && ilk.isNotEmpty) {
              sunucuMesaji = ilk.first.toString();
            }
          }
        }
      } catch (_) {
        // JSON dışında cevaplarda durum koduyla hata göstereceğiz.
      }

      if (response.statusCode == 401) {
        throw Exception('Oturum sona ermiş. Yeniden giriş yapın.');
      }
      if (response.statusCode == 403) {
        throw Exception('Şikayet durumunu değiştirmek için yönetici yetkisi gerekir.');
      }

      throw Exception(
        sunucuMesaji ??
            'Şikayet durumu güncellenemedi (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _kaydediliyor = false;
        });
      }
    }
  }

  Widget _bilgiSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(deger.isEmpty ? '-' : deger),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sikayet = widget.sikayet;

    return Scaffold(
      appBar: AppBar(title: const Text('Şikayet Detayı')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sikayet.baslik,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _bilgiSatiri('Şikayet No', '#${sikayet.id}'),
                      _bilgiSatiri('Kategori', sikayet.kategori),
                      _bilgiSatiri('Hat', sikayet.hat),
                      _bilgiSatiri('Durak', sikayet.durak),
                      
_bilgiSatiri(
  'Şikayet Sahibi',
  sikayet.kullaniciAdi,
),
_bilgiSatiri(
  'Kullanıcı Türü',
  sikayet.misafirMi ? 'Misafir Kullanıcı' : 'Kayıtlı Kullanıcı',
),
if (sikayet.kullaniciEmail != null)
  _bilgiSatiri(
    'E-posta',
    sikayet.kullaniciEmail!,
  ),
if (sikayet.kullaniciTelefon != null)
  _bilgiSatiri(
    'Telefon Numarası',
    sikayet.kullaniciTelefon!,
  ),

                      _bilgiSatiri('Tarih', _tarihMetni(sikayet.tarih)),
                      _bilgiSatiri('Mevcut durum', sikayet.durum),
                      const Divider(height: 26),
                      Text(
                        'Açıklama',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(sikayet.aciklama),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ComplaintMedia(complaint: sikayet),
                      if (sikayet.latitude != null && sikayet.longitude != null)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                            builder: (_) => SikayetKonumSayfasi(latitude: sikayet.latitude!, longitude: sikayet.longitude!),
                          )),
                          icon: const Icon(Icons.location_on_outlined),
                          label: const Text('Şikayet Konumunu Göster'),
                        ),
                      Text(
                        'Şikayet Durumunu Değiştir',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _secilenDurum,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Yeni durum',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        items: _durumlar
                            .map(
                              (durum) => DropdownMenuItem<String>(
                                value: durum,
                                child: Text(durum),
                              ),
                            )
                            .toList(),
                        onChanged: _kaydediliyor
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _secilenDurum = value;
                                  _hataMesaji = null;
                                });
                              },
                      ),
                      if (_hataMesaji != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _hataMesaji!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _kaydediliyor ? null : _durumuKaydet,
                          icon: _kaydediliyor
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _kaydediliyor ? 'Kaydediliyor...' : 'Durumu Kaydet',
                          ),
                        ),
                      ),
                    ],
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
