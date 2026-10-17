import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'profil_duzenle.dart';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});

  @override
  State<ProfilSayfasi> createState() =>
      _ProfilSayfasiState();
}

class _ProfilSayfasiState
    extends State<ProfilSayfasi> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  late Future<Map<String, dynamic>>
      _kullaniciFuture;

  bool _cikisYapiliyor = false;
  bool _hesapDonduruluyor = false;
  bool _hesapSiliniyor = false;
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
      _kullaniciFuture =
          _apiService.getMe();
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

  // --------------------------------------------------
  // PROFİL FOTOĞRAFI SEÇ
  // --------------------------------------------------

  Future<void> _profilFotografiSec() async {
    if (_fotografIslemiYapiliyor) {
      return;
    }

    try {
      final file = await FilePicker.pickFile(
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
          _fotografIslemiYapiliyor =
              false;
        });
      }
    }
  }

  // --------------------------------------------------
  // PROFİL FOTOĞRAFI SİL
  // --------------------------------------------------

  Future<void> _profilFotografiSil() async {
    if (_fotografIslemiYapiliyor) {
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                  dialogContext,
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
                  dialogContext,
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

    if (onay != true) {
      return;
    }

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
          _fotografIslemiYapiliyor =
              false;
        });
      }
    }
  }

  // --------------------------------------------------
  // PROFİL FOTOĞRAFI MENÜSÜ
  // --------------------------------------------------

  Future<void>
      _fotografSecenekleriniGoster(
    bool fotografVar,
  ) async {
    if (_fotografIslemiYapiliyor) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons
                      .photo_library_outlined,
                ),
                title: Text(
                  fotografVar
                      ? 'Fotoğrafı Değiştir'
                      : 'Fotoğraf Seç',
                ),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                  );

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
                    Navigator.pop(
                      sheetContext,
                    );

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
                  Navigator.pop(
                    sheetContext,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // ŞİFRE İSTE DİYALOĞU
  // --------------------------------------------------

  Future<String?> _sifreIste({
  required String baslik,
  required String aciklama,
  required String butonMetni,
  required Color butonRengi,
}) async {
  String sifre = '';
  String? hataMesaji;
  bool sifreGoster = false;

  final sonuc = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {
          return AlertDialog(
            title: Text(
              baslik,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    aciklama,
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  TextField(
                    obscureText:
                        !sifreGoster,
                    autofocus: true,
                    onChanged: (value) {
                      sifre = value;

                      if (hataMesaji != null) {
                        setDialogState(() {
                          hataMesaji = null;
                        });
                      }
                    },
                    decoration:
                        InputDecoration(
                      labelText:
                          'Mevcut Şifre',
                      border:
                          const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setDialogState(
                            () {
                              sifreGoster =
                                  !sifreGoster;
                            },
                          );
                        },
                        icon: Icon(
                          sifreGoster
                              ? Icons
                                  .visibility_off
                              : Icons
                                  .visibility,
                        ),
                      ),
                      errorText:
                          hataMesaji,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Vazgeç',
                ),
              ),

              FilledButton(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      butonRengi,
                  foregroundColor:
                      Colors.white,
                ),
                onPressed: () {
                  final password =
                      sifre.trim();

                  if (password.isEmpty) {
                    setDialogState(() {
                      hataMesaji =
                          'Lütfen mevcut şifrenizi girin.';
                    });

                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    password,
                  );
                },
                child: Text(
                  butonMetni,
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return sonuc;
}

  // --------------------------------------------------
  // HESABI DONDUR
  // --------------------------------------------------

  Future<void> _hesabiDondur() async {
    if (_hesapDonduruluyor ||
        _hesapSiliniyor ||
        _cikisYapiliyor) {
      return;
    }

    final password =
        await _sifreIste(
      baslik: 'Hesabı Dondur',
      aciklama:
          'Hesabınız dondurulduğunda oturumunuz kapatılır. '
          '90 gün içinde tekrar giriş yaparsanız hesabınız '
          'otomatik olarak yeniden aktifleştirilir.\n\n'
          '90 gün boyunca giriş yapmazsanız hesabınız ve '
          'hesabınıza bağlı veriler kalıcı olarak silinir.',
      butonMetni: 'Hesabı Dondur',
      butonRengi: Colors.orange,
    );

    if (password == null) {
      return;
    }

    setState(() {
      _hesapDonduruluyor = true;
    });

    try {
      await _apiService.freezeAccount(
        password: password,
      );

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

      final mesaj = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        _hesapDonduruluyor = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            mesaj,
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // HESABI KALICI OLARAK SİL
  // --------------------------------------------------

  Future<void> _hesabiSil() async {
    if (_hesapSiliniyor ||
        _hesapDonduruluyor ||
        _cikisYapiliyor) {
      return;
    }

    final password =
        await _sifreIste(
      baslik:
          'Hesabı Kalıcı Olarak Sil',
      aciklama:
          'DİKKAT!\n\n'
          'Bu işlem geri alınamaz. Hesabınız ve '
          'hesabınıza bağlı veriler kalıcı olarak silinecektir.\n\n'
          'Devam etmek için mevcut şifrenizi girin.',
      butonMetni:
          'Kalıcı Olarak Sil',
      butonRengi: Colors.red,
    );

    if (password == null) {
      return;
    }

    if (!mounted) return;

    final sonOnay =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 42,
          ),
          title: const Text(
            'Son Onay',
            textAlign:
                TextAlign.center,
          ),
          content: const Text(
            'Hesabınız tamamen silinecek '
            've bu işlem geri alınamayacaktır.\n\n'
            'Hesabınızı gerçekten silmek istiyor musunuz?',
            textAlign:
                TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Evet, Hesabımı Sil',
              ),
            ),
          ],
        );
      },
    );

    if (sonOnay != true) {
      return;
    }

    setState(() {
      _hesapSiliniyor = true;
    });

    try {
      await _apiService.deleteAccount(
        password: password,
      );

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

      final mesaj = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        _hesapSiliniyor = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            mesaj,
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // ÇIKIŞ
  // --------------------------------------------------

  Future<void> _cikisYap() async {
    if (_cikisYapiliyor ||
        _hesapDonduruluyor ||
        _hesapSiliniyor) {
      return;
    }

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

  // --------------------------------------------------
  // ARAYÜZ
  // --------------------------------------------------

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
              (user['id'] ?? '')
                  .toString();

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
              (user[
                          'profile_photo_url'] ??
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
                  const EdgeInsets.all(
                20,
              ),
              children: [
                const SizedBox(
                  height: 10,
                ),

                // PROFİL FOTOĞRAFI
                Center(
                  child: Stack(
                    clipBehavior:
                        Clip.none,
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
                                    fit:
                                        BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const ColoredBox(
                                        color: Color(
                                          0xFFE8EAF6,
                                        ),
                                        child:
                                            Center(
                                          child:
                                              Icon(
                                            Icons
                                                .person,
                                            size:
                                                58,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const ColoredBox(
                                    color:
                                        Color(
                                      0xFFE8EAF6,
                                    ),
                                    child:
                                        Center(
                                      child: Icon(
                                        Icons
                                            .person,
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
                                  const EdgeInsets
                                      .all(
                                9,
                              ),
                              child:
                                  _fotografIslemiYapiliyor
                                      ? const SizedBox(
                                          width:
                                              20,
                                          height:
                                              20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .camera_alt_outlined,
                                          size:
                                              21,
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

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

                const SizedBox(
                  height: 5,
                ),

                Text(
                  iletisim,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

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
                    Icons
                        .camera_alt_outlined,
                  ),
                  label: Text(
                    fotografVar
                        ? 'Profil Fotoğrafını Değiştir'
                        : 'Profil Fotoğrafı Ekle',
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // HESAP BİLGİLERİ
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const Icon(
                          Icons
                              .edit_outlined,
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
                          Icons
                              .arrow_forward_ios,
                          size: 16,
                        ),
                        onTap:
                            _profiliDuzenle,
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading:
                            const Icon(
                          Icons
                              .person_outline,
                        ),
                        title:
                            const Text(
                          'Ad Soyad',
                        ),
                        subtitle:
                            Text(ad),
                      ),

                      if (email
                          .isNotEmpty) ...[
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading:
                              const Icon(
                            Icons
                                .email_outlined,
                          ),
                          title:
                              const Text(
                            'E-posta',
                          ),
                          subtitle:
                              Text(email),
                        ),
                      ],

                      if (phone
                          .isNotEmpty) ...[
                        const Divider(
                          height: 1,
                        ),
                        ListTile(
                          leading:
                              const Icon(
                            Icons
                                .phone_outlined,
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
                        leading:
                            const Icon(
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
                        leading:
                            const Icon(
                          Icons
                              .lock_outline,
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
                                          ? Icons
                                              .visibility_off
                                          : Icons
                                              .visibility,
                                    ),
                                  ),
                      ),

                      const Divider(
                        height: 1,
                      ),

                      ListTile(
                        leading:
                            const Icon(
                          Icons
                              .password_outlined,
                        ),
                        title:
                            const Text(
                          'Şifreyi Değiştir',
                        ),
                        trailing:
                            const Icon(
                          Icons
                              .arrow_forward_ios,
                          size: 16,
                        ),
                        onTap:
                            _sifreyiDegistir,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ÇIKIŞ YAP
                SizedBox(
                  height: 50,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _cikisYapiliyor ||
                                _hesapDonduruluyor ||
                                _hesapSiliniyor
                            ? null
                            : _cikisYap,
                    icon: _cikisYapiliyor
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

                const SizedBox(
                  height: 14,
                ),

                // HESABI DONDUR
                SizedBox(
                  height: 50,
                  child:
                      OutlinedButton.icon(
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.orange
                              .shade800,
                      side: BorderSide(
                        color: Colors
                            .orange
                            .shade700,
                      ),
                    ),
                    onPressed:
                        _hesapDonduruluyor ||
                                _hesapSiliniyor ||
                                _cikisYapiliyor
                            ? null
                            : _hesabiDondur,
                    icon:
                        _hesapDonduruluyor
                            ? const SizedBox(
                                width: 20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .pause_circle_outline,
                              ),
                    label: Text(
                      _hesapDonduruluyor
                          ? 'Hesap Donduruluyor...'
                          : 'Hesabı Dondur',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Hesabınızı dondurursanız 90 gün içinde '
                  'tekrar giriş yaparak yeniden aktif edebilirsiniz.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                // HESABI KALICI SİL
                SizedBox(
                  height: 50,
                  child:
                      OutlinedButton.icon(
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.red,
                      side:
                          const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                    onPressed:
                        _hesapSiliniyor ||
                                _hesapDonduruluyor ||
                                _cikisYapiliyor
                            ? null
                            : _hesabiSil,
                    icon:
                        _hesapSiliniyor
                            ? const SizedBox(
                                width: 20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .delete_forever,
                              ),
                    label: Text(
                      _hesapSiliniyor
                          ? 'Hesap Siliniyor...'
                          : 'Hesabı Kalıcı Olarak Sil',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Kalıcı silme işlemi geri alınamaz.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}