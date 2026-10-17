import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'misafir_sikayet.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _loading = false;
  bool _sifreGizli = true;
  bool _beniHatirla = false;
  bool _bilgilerYukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kayitliBilgileriGetir();
  }

  Future<void> _kayitliBilgileriGetir() async {
    final remembered = await _authStorage.isRemembered();

    if (remembered) {
      final identifier = await _authStorage.getSavedIdentifier();
      final password = await _authStorage.getSavedPassword();

      _identifierController.text = identifier ?? '';
      _passwordController.text = password ?? '';
    }

    if (!mounted) return;

    setState(() {
      _beniHatirla = remembered;
      _bilgilerYukleniyor = false;
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      final result = await _apiService.login(identifier, password);

      if (result['must_reset_password'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Şifrenizi yenilemeniz gerekiyor.',
            ),
          ),
        );

        Navigator.pushNamed(context, '/sifremi-unuttum');
        return;
      }

      if (result['success'] == true) {
        // Giriş yapan kişinin rolü Laravel'den doğrulanır.
        final kullanici = await _apiService.getMe();
        final rol = kullanici['role']?.toString() ?? 'user';

        await _authStorage.saveCurrentPassword(password);

        if (_beniHatirla) {
          await _authStorage.saveLoginInfo(
            identifier: identifier,
            password: password,
          );
        } else {
          await _authStorage.clearLoginInfo();
        }

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          (rol == 'admin' || rol == 'super_admin') ? '/admin' : '/ana',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş yapılamadı: $e'),
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

  Future<void> _misafirSikayetAc() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const MisafirSikayetSayfasi(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bilgilerYukleniyor) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Akıllı Toplu Taşıma',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'E-posta veya Telefon',
                      hintText: 'ornek@mail.com veya 05551234567',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'E-posta veya telefon girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _sifreGizli,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _sifreGizli = !_sifreGizli;
                          });
                        },
                        icon: Icon(
                          _sifreGizli ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifrenizi girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _beniHatirla,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Beni Hatırla'),
                          onChanged: (value) {
                            setState(() {
                              _beniHatirla = value ?? false;
                            });
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/sifremi-unuttum');
                        },
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _girisYap,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Giriş Yap'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _misafirSikayetAc,
                      icon: const Icon(Icons.report_outlined),
                      label: const Text('Kayıt Olmadan Şikayet Et'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Misafir şikayetinde e-posta doğrulaması zorunludur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/kayit');
                    },
                    child: const Text('Hesabınız yok mu? Kayıt olun'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
