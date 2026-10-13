import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ProfilDuzenleSayfasi
    extends StatefulWidget {
  const ProfilDuzenleSayfasi({
    super.key,
  });

  @override
  State<ProfilDuzenleSayfasi>
      createState() =>
          _ProfilDuzenleSayfasiState();
}

class _ProfilDuzenleSayfasiState
    extends State<ProfilDuzenleSayfasi> {
  final ApiService _apiService =
      ApiService();

  final AuthStorage _authStorage =
      AuthStorage();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _codeController =
      TextEditingController();

  bool _loading = true;
  bool _isimKaydediliyor = false;
  bool _kodGonderiliyor = false;
  bool _kodGonderildi = false;
  bool _emailDogrulaniyor = false;
  bool _sifreGizli = true;

  String _eskiEmail = '';

  @override
  void initState() {
    super.initState();
    _kullaniciyiYukle();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();

    super.dispose();
  }

  Future<void> _kullaniciyiYukle() async {
    try {
      final user =
          await _apiService.getMe();

      _nameController.text =
          (user['name'] ?? '').toString();

      _eskiEmail =
          (user['email'] ?? '').toString();

      _emailController.text =
          _eskiEmail;

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Profil bilgileri alınamadı: $e',
          ),
        ),
      );
    }
  }

  Future<void> _ismiKaydet() async {
    final name =
        _nameController.text.trim();

    if (name.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Geçerli bir ad soyad girin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isimKaydediliyor = true;
    });

    try {
      await _apiService.updateProfile(
        name: name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Ad soyad başarıyla güncellendi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Güncelleme başarısız: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isimKaydediliyor = false;
        });
      }
    }
  }

  Future<void> _emailKoduGonder() async {
    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text;

    if (email.isEmpty ||
        !email.contains('@')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Geçerli bir e-posta adresi girin.',
          ),
        ),
      );

      return;
    }

    if (email.toLowerCase() ==
        _eskiEmail.toLowerCase()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Yeni e-posta mevcut e-posta ile aynı.',
          ),
        ),
      );

      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Mevcut şifrenizi girin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _kodGonderiliyor = true;
    });

    try {
      await _apiService
          .requestEmailChangeCode(
        email: email,
        currentPassword: password,
      );

      if (!mounted) return;

      setState(() {
        _kodGonderildi = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Yeni e-posta adresinize '
            '6 haneli kod gönderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Kod gönderilemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _kodGonderiliyor = false;
        });
      }
    }
  }

  Future<void> _emailDogrula() async {
    final code =
        _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '6 haneli doğrulama kodunu girin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _emailDogrulaniyor = true;
    });

    try {
      final yeniEmail =
          _emailController.text.trim();

      await _apiService.confirmEmailChange(
        code: code,
      );

      final savedIdentifier =
          await _authStorage
              .getSavedIdentifier();

      if (savedIdentifier != null &&
          savedIdentifier.toLowerCase() ==
              _eskiEmail.toLowerCase()) {
        await _authStorage
            .updateSavedIdentifier(
          yeniEmail,
        );
      }

      _eskiEmail = yeniEmail;

      _passwordController.clear();
      _codeController.clear();

      if (!mounted) return;

      setState(() {
        _kodGonderildi = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta adresiniz başarıyla değiştirildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'E-posta değiştirilemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _emailDogrulaniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Profili Düzenle'),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(20),
              children: [
                const Text(
                  'Ad Soyad',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      _nameController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isimKaydediliyor
                            ? null
                            : _ismiKaydet,
                    icon: const Icon(
                      Icons.save_outlined,
                    ),
                    label: Text(
                      _isimKaydediliyor
                          ? 'Kaydediliyor...'
                          : 'Ad Soyadı Kaydet',
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Divider(),

                const SizedBox(height: 20),

                const Text(
                  'E-posta Değiştir',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Güvenlik için mevcut şifrenizi '
                  'doğruladıktan sonra yeni e-posta '
                  'adresinize 6 haneli kod göndereceğiz.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  enabled: !_kodGonderildi,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Yeni E-posta',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                      _passwordController,
                  enabled: !_kodGonderildi,
                  obscureText:
                      _sifreGizli,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Mevcut Şifre',
                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                    ),
                    border:
                        const OutlineInputBorder(),
                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _sifreGizli =
                              !_sifreGizli;
                        });
                      },
                      icon: Icon(
                        _sifreGizli
                            ? Icons.visibility
                            : Icons
                                .visibility_off,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (!_kodGonderildi)
                  SizedBox(
                    height: 48,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _kodGonderiliyor
                              ? null
                              : _emailKoduGonder,
                      icon: const Icon(
                        Icons.send_outlined,
                      ),
                      label: Text(
                        _kodGonderiliyor
                            ? 'Gönderiliyor...'
                            : 'Doğrulama Kodu Gönder',
                      ),
                    ),
                  ),

                if (_kodGonderildi) ...[
                  TextField(
                    controller:
                        _codeController,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 6,
                    decoration:
                        const InputDecoration(
                      labelText:
                          '6 Haneli Kod',
                      prefixIcon: Icon(
                        Icons.verified_outlined,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 48,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _emailDogrulaniyor
                              ? null
                              : _emailDogrula,
                      icon: const Icon(
                        Icons.check_circle_outline,
                      ),
                      label: Text(
                        _emailDogrulaniyor
                            ? 'Doğrulanıyor...'
                            : 'E-postayı Değiştir',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
    );
  }
}