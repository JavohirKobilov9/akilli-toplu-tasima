import 'package:flutter/material.dart';

import '../models/sikayet.dart';
import '../services/api_service.dart';

class SuperAdminAnalizSayfasi extends StatefulWidget {
  const SuperAdminAnalizSayfasi({super.key});

  @override
  State<SuperAdminAnalizSayfasi> createState() =>
      _SuperAdminAnalizSayfasiState();
}

class _SuperAdminAnalizSayfasiState extends State<SuperAdminAnalizSayfasi> {
  final _api = ApiService();
  List<Sikayet> _veriler = [];
  List<String> _tumHatlar = [];
  bool _yukleniyor = true;
  String? _hata;
  DateTimeRange? _tarih;
  String? _hat;
  String _veriTuru = 'tumu';

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final kullanici = await _api.getMe();
      if (kullanici['role'] != 'super_admin' && kullanici['role'] != 'admin') {
        throw Exception('Bu ekran için yönetici yetkisi gerekiyor.');
      }
      final veriler = await _api.getAdminSikayetler();
      final hatlar = await _api.getLines();
      final hatAdlari = hatlar.map((h) => '${h.code} - ${h.name}').toList();
      if (!mounted) return;
      setState(() {
        _veriler = veriler;
        _tumHatlar = hatAdlari;
        if (_hat != null &&
    !hatAdlari.contains(_hat) &&
    !veriler.any((s) => s.hat == _hat)) {
  _hat = null;
}

        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  List<Sikayet> get _filtreli => _veriler.where((s) {
    final tarih = s.tarih.toLocal();
    final baslangic = _tarih?.start;
    final bitis = _tarih == null
        ? null
        : DateTime(_tarih!.end.year, _tarih!.end.month, _tarih!.end.day + 1);
    return (_hat == null || s.hat == _hat) &&
        (_veriTuru == 'tumu' ||
            (_veriTuru == 'misafir' ? s.misafirMi : s.kayitliMi)) &&
        (baslangic == null || !tarih.isBefore(baslangic)) &&
        (bitis == null || tarih.isBefore(bitis));
  }).toList();

  String _gun(DateTime d) => '${d.day}.${d.month}.${d.year}';

  Future<void> _tarihSec() async {
    var ilk = DateTime(2020);
    var son = DateTime.now();
    for (final s in _veriler) {
      final d = s.tarih.toLocal();
      if (d.isBefore(ilk)) ilk = d;
      if (d.isAfter(son)) son = d;
    }
    final secim = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ilk.year, ilk.month, ilk.day),
      lastDate: DateTime(son.year, son.month, son.day),
      initialDateRange: _tarih,
      helpText: 'Tarih aralığı seç',
      saveText: 'Uygula',
    );
    if (secim == null || !mounted) return;
    setState(() => _tarih = secim);
  }

  Map<String, int> _grupla(
    List<Sikayet> veriler,
    String Function(Sikayet) alan,
  ) {
    final sonuc = <String, int>{};
    for (final s in veriler) {
      final ad = alan(s).trim();
      final etiket = ad.isEmpty ? 'Bilgi yok' : ad;
      sonuc.update(etiket, (sayi) => sayi + 1, ifAbsent: () => 1);
    }
    return sonuc;
  }

  List<MapEntry<String, int>> _sirala(Map<String, int> gruplar) =>
      gruplar.entries.toList()..sort((a, b) {
        final sonuc = b.value.compareTo(a.value);
        return sonuc == 0 ? a.key.compareTo(b.key) : sonuc;
      });

  Widget _grafik(
    String baslik,
    List<MapEntry<String, int>> satirlar, {
    bool aylik = false,
  }) {
    final enBuyuk = satirlar.fold<int>(
      0,
      (en, s) => s.value > en ? s.value : en,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (satirlar.isEmpty)
              const Text('Seçilen filtrelerde şikayet yok.'),
            for (final s in satirlar)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${aylik ? '${s.key.substring(5)}/${s.key.substring(0, 4)}' : s.key} • ${s.value}',
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: '${s.key}: ${s.value} şikayet',
                      child: LinearProgressIndicator(
                        value: enBuyuk == 0 ? 0 : s.value / enBuyuk,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final veriler = _filtreli;
    final hatlar =
        [
          ..._tumHatlar,
          ..._veriler.map((s) => s.hat),
        ].where((s) => s.trim().isNotEmpty).toSet().toList()..sort((a, b) {
          final desen = RegExp(r'BRT\s*(\d+)', caseSensitive: false);
          final x = int.tryParse(desen.firstMatch(a)?.group(1) ?? '');
          final y = int.tryParse(desen.firstMatch(b)?.group(1) ?? '');
          final sonuc = (x ?? 999999).compareTo(y ?? 999999);
          return sonuc == 0 ? a.compareTo(b) : sonuc;
        });
    final aylar = _grupla(veriler, (s) {
      final d = s.tarih.toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    // Seçilen aralıkta (veya verinin ilk ve son ayı arasında) boş ayları da göster.
    if (_tarih != null || aylar.isNotEmpty) {
      final anahtarlar = aylar.keys.toList()..sort();
      final ilk = _tarih?.start ?? DateTime.parse('${anahtarlar.first}-01');
      final son = _tarih?.end ?? DateTime.parse('${anahtarlar.last}-01');
      var ay = DateTime(ilk.year, ilk.month);
      while (!ay.isAfter(DateTime(son.year, son.month))) {
        aylar.putIfAbsent(
          '${ay.year}-${ay.month.toString().padLeft(2, '0')}',
          () => 0,
        );
        ay = DateTime(ay.year, ay.month + 1);
      }
    }
    final aylik = aylar.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sayaclar = <String, int>{
      'Toplam': veriler.length,
      'Beklemede': veriler.where((s) => s.durum == 'Beklemede').length,
      'İnceleniyor': veriler.where((s) => s.durum == 'İnceleniyor').length,
      'Çözüldü': veriler.where((s) => s.durum == 'Çözüldü').length,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şikayet Analizleri'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukleniyor ? null : _yukle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_hata!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _yukle,
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _veriTuru,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı türü',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'tumu',
                      child: Text('Tüm kayıtlar'),
                    ),
                    DropdownMenuItem(
                      value: 'misafir',
                      child: Text('Misafir kullanıcılar'),
                    ),
                    DropdownMenuItem(
                      value: 'kayitli',
                      child: Text('Kayıtlı kullanıcılar'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _veriTuru = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_hat),
                  initialValue: _hat ?? '__tum__',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Hat'),
                  items: [
                    const DropdownMenuItem(
                      value: '__tum__',
                      child: Text('Tüm hatlar'),
                    ),
                    for (final h in hatlar)
                      DropdownMenuItem(
                        value: h,
                        child: Text(h, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _hat = v == '__tum__' ? null : v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _tarihSec,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _tarih == null
                            ? 'Tüm tarihler'
                            : '${_gun(_tarih!.start)} – ${_gun(_tarih!.end)}',
                      ),
                    ),
                    if (_tarih != null)
                      TextButton(
                        onPressed: () => setState(() => _tarih = null),
                        child: const Text('Tarihi temizle'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Seçili filtrelerde ${veriler.length} şikayet • '
                  '${veriler.where((s) => s.misafirMi).length} misafir, '
                  '${veriler.where((s) => s.kayitliMi).length} kayıtlı',
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, boyut) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in sayaclar.entries)
                        SizedBox(
                          width: (boyut.maxWidth - 8) / 2,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${s.value}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  Text(s.key),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _grafik(
                  'En çok şikayet gelen 5 hat',
                  _sirala(_grupla(veriler, (s) => s.hat)).take(5).toList(),
                ),
                _grafik(
                  'Kategorilere göre şikayet sayısı',
                  _sirala(_grupla(veriler, (s) => s.kategori)),
                ),
                _grafik('Aylara göre şikayet sayısı', aylik, aylik: true),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Grafikler seçilen filtrelerdeki kayıt sayılarını gösterir. '
                    'Hat sıralaması, yolcu veya sefer sayısına göre oranlanmamıştır.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}
