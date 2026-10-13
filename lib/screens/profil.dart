import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'profil_duzenle.dart';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  late Future<Map<String, dynamic>> _kullaniciFuture;

  bool _cikisYapiliyor = false;
  bool _fotografIslemiYapiliyor = false;

  String? _kayitliSifre;
  bool _sifreGorunuyor = false;

  @override
  void initState() {
    super.initState();

    _kullaniciFuture = _apiService.getMe();
    _kayitliSifreyiGetir();
  }

  Future<void> _kayitliSifreyiGetir() async {
    final password =
        await _authStorage.getCurrentPassword();

    if (!mounted) return;

    setState(() {
      _kayitliSifre = password;
    });
  }

  void _yenile() {
    setState(() {
      _kullaniciFuture = _apiService.getMe();
    });
  }

  Future<void> _profiliDuzenle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfilDuzenleSayfasi(),
      ),
    );

    if (!mounted) return;

    _yenile();
  }

  Future<void> _sifreyiDegistir() async {
    await Navigator.pushNamed(
      context,
      '/sifre-degistir',
    );

    if (!mounted) return;

    await _kayitliSifreyiGetir();
  }

  Future<void> _profilFotografiSec() async {
  if (_fotografIslemiYapiliyor) return;

  try {
    final file =
        await FilePicker.pickFile(
      type: FileType.image,
    );

    if (file == null) {
      return;
    }

    final filePath = file.path;

    if (filePath == null ||
        filePath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Seçilen fotoğrafın dosya yolu alınamadı.',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _fotografIslemiYapiliyor = true;
    });

    await _apiService.uploadProfilePhoto(
      filePath,
    );

    if (!mounted) return;

    _yenile();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Profil fotoğrafı başarıyla güncellendi.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Profil fotoğrafı yüklenemedi: $e',
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _fotografIslemiYapiliyor = false;
      });
    }
  }
}

  Future<void> _profilFotografiSil() async {
    if (_fotografIslemiYapiliyor) return;

    final onay =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Profil Fotoğrafını Sil',
          ),
          content: const Text(
            'Profil fotoğrafınızı silmek '
            'istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Sil',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    setState(() {
      _fotografIslemiYapiliyor = true;
    });

    try {
      await _apiService
          .deleteProfilePhoto();

      if (!mounted) return;

      _yenile();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profil fotoğrafı silindi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Profil fotoğrafı silinemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _fotografIslemiYapiliyor = false;
        });
      }
    }
  }

  Future<void> _fotografSecenekleriniGoster(
    bool fotografVar,
  ) async {
    if (_fotografIslemiYapiliyor) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 10,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                  ),
                  title: Text(
                    fotografVar
                        ? 'Fotoğrafı Değiştir'
                        : 'Fotoğraf Seç',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _profilFotografiSec();
                  },
                ),
                if (fotografVar)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Fotoğrafı Sil',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _profilFotografiSil();
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.close,
                  ),
                  title: const Text(
                    'Vazgeç',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cikisYap() async {
    if (_cikisYapiliyor) return;

    setState(() {
      _cikisYapiliyor = true;
    });

    try {
      await _apiService.logout();

      await _authStorage
          .clearCurrentPassword();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/giris',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cikisYapiliyor = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Çıkış yapılamadı: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yenile,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body:
          FutureBuilder<Map<String, dynamic>>(
        future: _kullaniciFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: _yenile,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Profil yüklenemedi - Tekrar Dene',
                ),
              ),
            );
          }

          final user =
              snapshot.data ?? {};

          final id =
              (user['id'] ?? '').toString();

          final ad =
              (user['name'] ??
                      'Kullanıcı')
                  .toString();

          final email =
              (user['email'] ?? '')
                  .toString();

          final phone =
              (user['phone'] ?? '')
                  .toString();

          final profilePhotoUrl =
              (user['profile_photo_url'] ??
                      '')
                  .toString();

          final fotografVar =
              profilePhotoUrl.isNotEmpty;

          final iletisim =
              email.isNotEmpty
                  ? email
                  : phone.isNotEmpty
                      ? phone
                      : 'İletişim bilgisi yok';

          return RefreshIndicator(
            onRefresh: () async {
              _yenile();
              await _kullaniciFuture;
            },
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),

                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        shape:
                            const CircleBorder(),
                        clipBehavior:
                            Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            _fotografSecenekleriniGoster(
                              fotografVar,
                            );
                          },
                          child: SizedBox(
                            width: 108,
                            height: 108,
                            child: fotografVar
                                ? Image.network(
                                    profilePhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const ColoredBox(
                                        color:
                                            Color(0xFFE8EAF6),
                                        child: Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 58,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const ColoredBox(
                                    color:
                                        Color(0xFFE8EAF6),
                                    child: Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 58,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          elevation: 3,
                          shape:
                              const CircleBorder(),
                          child: InkWell(
                            customBorder:
                                const CircleBorder(),
                            onTap: () {
                              _fotografSecenekleriniGoster(
                                fotografVar,
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                9,
                              ),
                              child:
                                  _fotografIslemiYapiliyor
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 21,
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  ad,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  iletisim,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                TextButton.icon(
                  onPressed:
                      _fotografIslemiYapiliyor
                          ? null
                          : () {
                              _fotografSecenekleriniGoster(
                                fotografVar,
                              );
                            },
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  label: Text(
                    fotografVar
                        ? 'Profil Fotoğrafını Değiştir'
                        : 'Profil Fotoğrafı Ekle',
                  ),
                ),

                const SizedBox(height: 22),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.edit_outlined,
                        ),
                        title:
                            const Text(
                          'Profili Düzenle',
                        ),
                        subtitle:
                            const Text(
                          'Ad soyad veya e-posta adresini değiştir',
                        ),
                        trailing:
                            const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        onTap:
                            _profiliDuzenle,
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                        ),
                        title:
                            const Text(
                          'Ad Soyad',
                        ),
                        subtitle:
                            Text(ad),
                      ),

                      if (email.isNotEmpty) ...[
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading:
                              const Icon(
                            Icons.email_outlined,
                          ),
                          title:
                              const Text(
                            'E-posta',
                          ),
                          subtitle:
                              Text(email),
                        ),
                      ],

                      if (phone.isNotEmpty) ...[
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading:
                              const Icon(
                            Icons.phone_outlined,
                          ),
                          title:
                              const Text(
                            'Telefon',
                          ),
                          subtitle:
                              Text(phone),
                        ),
                      ],

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.fingerprint,
                        ),
                        title:
                            const Text(
                          'Kullanıcı No',
                        ),
                        subtitle:
                            Text('#$id'),
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.lock_outline,
                        ),
                        title:
                            const Text(
                          'Şifre',
                        ),
                        subtitle: Text(
                          _kayitliSifre ==
                                  null
                              ? 'Şifre cihazda kayıtlı değil'
                              : _sifreGorunuyor
                                  ? _kayitliSifre!
                                  : '••••••••',
                        ),
                        trailing:
                            _kayitliSifre ==
                                    null
                                ? null
                                : IconButton(
                                    tooltip:
                                        _sifreGorunuyor
                                            ? 'Şifreyi gizle'
                                            : 'Şifreyi göster',
                                    onPressed:
                                        () {
                                      setState(
                                        () {
                                          _sifreGorunuyor =
                                              !_sifreGorunuyor;
                                        },
                                      );
                                    },
                                    icon: Icon(
                                      _sifreGorunuyor
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.password_outlined,
                        ),
                        title:
                            const Text(
                          'Şifreyi Değiştir',
                        ),
                        trailing:
                            const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                        onTap:
                            _sifreyiDegistir,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _cikisYapiliyor
                            ? null
                            : _cikisYap,
                    icon:
                        _cikisYapiliyor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.logout,
                              ),
                    label: Text(
                      _cikisYapiliyor
                          ? 'Çıkış Yapılıyor...'
                          : 'Çıkış Yap',
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
