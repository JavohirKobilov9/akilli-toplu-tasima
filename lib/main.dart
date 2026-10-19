import 'package:flutter/material.dart';

import 'screens/admin_ana_sayfa.dart';
import 'screens/sifremi_unuttum.dart';
import 'screens/giris.dart';
import 'screens/ana_sayfa.dart';
import 'screens/kayit.dart';
import 'screens/sikayet_olustur.dart';
import 'screens/sikayetlerim.dart';
import 'screens/profil.dart';
import 'screens/sifre_degistir.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'screens/bildirimler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();
  runApp(const AkilliTopluTasimaApp());
}

class AkilliTopluTasimaApp extends StatelessWidget {
  const AkilliTopluTasimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Akıllı Toplu Taşıma',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      home: const OturumKontrolSayfasi(),
      routes: {
        '/bildirimler': (context) => const BildirimlerSayfasi(),
        '/giris': (context) => const GirisSayfasi(),
        '/kayit': (context) => const KayitSayfasi(),
        '/ana': (context) => const AnaSayfa(),
        '/admin': (context) => const AdminAnaSayfa(),
        '/sikayet-olustur': (context) => const SikayetOlusturSayfasi(),
        '/sikayetlerim': (context) => const SikayetlerimSayfasi(),
        '/profil': (context) => const ProfilSayfasi(),
        '/sifremi-unuttum': (context) => const SifremiUnuttumSayfasi(),
        '/sifre-degistir': (context) => const SifreDegistirSayfasi(),
      },
    );
  }
}

class OturumKontrolSayfasi extends StatefulWidget {
  const OturumKontrolSayfasi({super.key});

  @override
  State<OturumKontrolSayfasi> createState() => _OturumKontrolSayfasiState();
}

class _OturumKontrolSayfasiState extends State<OturumKontrolSayfasi> {
  final ApiService _apiService = ApiService();

  late final Future<String?> _oturumKontrol;

  @override
  void initState() {
    super.initState();
    _oturumKontrol = _rolGetir();
  }

  Future<String?> _rolGetir() async {
    try {
      // Rolü telefondan değil, Laravel'in /me API'sinden öğreniyoruz.
      final kullanici = await _apiService.getMe();
      return kullanici['role']?.toString() ?? 'user';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _oturumKontrol,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 70, color: Colors.indigo),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Oturum kontrol ediliyor...'),
                ],
              ),
            ),
          );
        }

        final rol = snapshot.data;
        if (rol == 'admin' || rol == 'super_admin') {
          return const AdminAnaSayfa();
        }
        if (rol == 'user') {
          return const AnaSayfa();
        }
        return const GirisSayfasi();
      },
    );
  }
}
