import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({super.key});

  @override
  State<KayitSayfasi> createState() =>
      _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _adController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _loading = false;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email =
        _emailController.text.trim();

    final phone =
        _phoneController.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-posta veya telefon numarasından '
            'en az birini girmelisiniz.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final sonuc =
          await _apiService.register(
        _adController.text.trim(),
        email.isEmpty ? null : email,
        phone.isEmpty ? null : phone,
        _passwordController.text,
      );

      if (!mounted) return;

      if (sonuc['success'] == true) {
        await _authStorage.saveCurrentPassword(
          _passwordController.text,
        );

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/ana',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kayıt oluşturulamadı: $e',
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
          'Kayıt Ol',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                const Icon(
                  Icons.person_add_alt_1,
                  size: 70,
                  color: Colors.indigo,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ad soyad girin.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText:
                        'E-posta (opsiyonel)',
                    hintText:
                        'ornek@gmail.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText:
                        'Telefon (opsiyonel)',
                    hintText:
                        '05551234567',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'E-posta veya telefon numarasından '
                  'en az birini girmelisiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _passwordController,
                  obscureText:
                      _sifreGizli,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    border:
                        const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _sifreGizli =
                              !_sifreGizli;
                        });
                      },
                      icon: Icon(
                        _sifreGizli
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Şifrenizi girin.';
                    }

                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _kayitOl,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kayıt Ol',
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/giris',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Zaten hesabınız var mı? Giriş yapın',
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