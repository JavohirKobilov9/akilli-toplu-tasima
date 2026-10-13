
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SifremiUnuttumSayfasi
    extends StatefulWidget {
  const SifremiUnuttumSayfasi({
    super.key,
  });

  @override
  State<SifremiUnuttumSayfasi>
      createState() =>
          _SifremiUnuttumSayfasiState();
}

class _SifremiUnuttumSayfasiState
    extends State<SifremiUnuttumSayfasi> {
  final ApiService _apiService =
      ApiService();

  final _identifierController =
      TextEditingController();

  final _codeController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _kodGonderildi = false;
  bool _loading = false;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _kodGonder() async {
    final identifier =
        _identifierController.text.trim();

    if (identifier.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _apiService
          .requestPasswordResetCode(
        identifier,
      );

      if (!mounted) return;

      setState(() {
        _kodGonderildi = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '6 haneli doğrulama kodu gönderildi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
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

  Future<void> _sifreyiYenile() async {
    if (_codeController.text.length != 6 ||
        _passwordController.text.length <
            6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '6 haneli kodu ve en az '
            '6 karakterlik yeni şifreyi girin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _apiService.resetPassword(
        identifier:
            _identifierController.text
                .trim(),
        code:
            _codeController.text.trim(),
        password:
            _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Şifreniz başarıyla yenilendi.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
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
        title:
            const Text('Şifremi Unuttum'),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: Colors.indigo,
            ),

            const SizedBox(height: 24),

            TextField(
              controller:
                  _identifierController,
              enabled: !_kodGonderildi,
              decoration:
                  const InputDecoration(
                labelText:
                    'E-posta veya Telefon',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (!_kodGonderildi)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : _kodGonder,
                  child: const Text(
                    'Kod Gönder',
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
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                    _passwordController,
                obscureText: _sifreGizli,
                decoration:
                    InputDecoration(
                  labelText: 'Yeni Şifre',
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

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : _sifreyiYenile,
                  child: const Text(
                    'Şifreyi Yenile',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}