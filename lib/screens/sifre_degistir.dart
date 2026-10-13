import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class SifreDegistirSayfasi extends StatefulWidget {
  const SifreDegistirSayfasi({
    super.key,
  });

  @override
  State<SifreDegistirSayfasi> createState() =>
      _SifreDegistirSayfasiState();
}

class _SifreDegistirSayfasiState
    extends State<SifreDegistirSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mevcutSifreController =
      TextEditingController();

  final TextEditingController _yeniSifreController =
      TextEditingController();

  final TextEditingController _yeniSifreTekrarController =
      TextEditingController();

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _loading = false;

  bool _mevcutSifreGizli = true;
  bool _yeniSifreGizli = true;
  bool _yeniSifreTekrarGizli = true;

  @override
  void dispose() {
    _mevcutSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();

    super.dispose();
  }

  Future<void> _sifreyiDegistir() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mevcutSifre =
        _mevcutSifreController.text;

    final yeniSifre =
        _yeniSifreController.text;

    final yeniSifreTekrar =
        _yeniSifreTekrarController.text;

    if (yeniSifre != yeniSifreTekrar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yeni şifreler aynı değil.',
          ),
        ),
      );

      return;
    }

    if (mevcutSifre == yeniSifre) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yeni şifre mevcut şifreyle aynı olamaz.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _apiService.changePassword(
        currentPassword: mevcutSifre,
        newPassword: yeniSifre,
      );

      // Beni Hatırla açıksa kayıtlı şifreyi günceller.
      await _authStorage.updateSavedPassword(
        yeniSifre,
      );

      // Profilde gösterilecek mevcut oturum şifresini günceller.
      await _authStorage.saveCurrentPassword(
        yeniSifre,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şifreniz başarıyla değiştirildi.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Şifre değiştirilemedi: $e',
          ),
        ),
      );
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
          'Şifreyi Değiştir',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.lock_reset,
                size: 80,
                color: Colors.indigo,
              ),

              const SizedBox(height: 20),

              const Text(
                'Şifre Değiştir',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Mevcut şifrenizi doğrulayarak '
                'yeni bir şifre belirleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _mevcutSifreController,
                obscureText: _mevcutSifreGizli,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _mevcutSifreGizli =
                            !_mevcutSifreGizli;
                      });
                    },
                    icon: Icon(
                      _mevcutSifreGizli
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Mevcut şifrenizi girin.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _yeniSifreController,
                obscureText: _yeniSifreGizli,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: const Icon(
                    Icons.password_outlined,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _yeniSifreGizli =
                            !_yeniSifreGizli;
                      });
                    },
                    icon: Icon(
                      _yeniSifreGizli
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Yeni şifrenizi girin.';
                  }

                  if (value.length < 6) {
                    return 'Yeni şifre en az 6 karakter olmalıdır.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller:
                    _yeniSifreTekrarController,
                obscureText:
                    _yeniSifreTekrarGizli,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  prefixIcon: const Icon(
                    Icons.password_outlined,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _yeniSifreTekrarGizli =
                            !_yeniSifreTekrarGizli;
                      });
                    },
                    icon: Icon(
                      _yeniSifreTekrarGizli
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Yeni şifreyi tekrar girin.';
                  }

                  if (value !=
                      _yeniSifreController.text) {
                    return 'Yeni şifreler aynı değil.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _sifreyiDegistir,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),
                  label: Text(
                    _loading
                        ? 'Değiştiriliyor...'
                        : 'Şifreyi Değiştir',
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