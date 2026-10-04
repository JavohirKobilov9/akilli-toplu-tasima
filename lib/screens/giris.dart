import 'package:flutter/material.dart';

import '../services/api_service.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _emailController.dispose();
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

    final sonuc = await _apiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (sonuc) {
      Navigator.pushReplacementNamed(context, '/ana');
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  const SizedBox(height: 8),

                  const Text(
                    'Toplu taşıma deneyimini birlikte iyileştirelim.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'E-posta adresinizi girin.';
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
                      if (value == null || value.isEmpty) {
                        return 'Şifrenizi girin.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _girisYap,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Giriş Yap'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/kayit');
                    },
                    child: const Text(
                      'Hesabınız yok mu? Kayıt olun',
                    ),
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