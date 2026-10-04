import 'package:flutter/material.dart';

import '../services/api_service.dart';

class KayitSayfasi extends StatefulWidget {
  const KayitSayfasi({super.key});

  @override
  State<KayitSayfasi> createState() => _KayitSayfasiState();
}

class _KayitSayfasiState extends State<KayitSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _adController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _adController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final sonuc = await _apiService.register(
      _adController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (sonuc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı!'),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.person_add_alt_1,
                  size: 70,
                  color: Colors.indigo,
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _adController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad girin.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Geçerli bir e-posta girin.';
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
                        _sifreGizli
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _kayitOl,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Kayıt Ol'),
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