import 'package:flutter/material.dart';
import 'screens/sifremi_unuttum.dart';
import 'screens/giris.dart';
import 'screens/ana_sayfa.dart';
import 'screens/kayit.dart';
import 'screens/sikayet_olustur.dart';
import 'screens/sikayetlerim.dart';
import 'screens/profil.dart';
import 'screens/sifre_degistir.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    const AkilliTopluTasimaApp(),
  );
}

class AkilliTopluTasimaApp
    extends StatelessWidget {
  const AkilliTopluTasimaApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title:
          'Akıllı Toplu Taşıma',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
            Colors.indigo,
        scaffoldBackgroundColor:
            const Color(
          0xFFF7F8FC,
        ),
      ),

      home: const OturumKontrolSayfasi(),

      routes: {
        '/giris': (context) =>
            const GirisSayfasi(),

        '/kayit': (context) =>
            const KayitSayfasi(),

        '/ana': (context) =>
            const AnaSayfa(),

        '/sikayet-olustur':
            (context) =>
                const SikayetOlusturSayfasi(),

        '/sikayetlerim':
            (context) =>
                const SikayetlerimSayfasi(),

        '/profil': (context) =>
            const ProfilSayfasi(),
         '/sifremi-unuttum': (context) =>
    const SifremiUnuttumSayfasi(),   

     '/sifre-degistir': (context) =>
    const SifreDegistirSayfasi(),
    
      },
    );
  }
}

class OturumKontrolSayfasi
    extends StatefulWidget {
  const OturumKontrolSayfasi({
    super.key,
  });

  @override
  State<OturumKontrolSayfasi>
      createState() =>
          _OturumKontrolSayfasiState();
}

class _OturumKontrolSayfasiState
    extends State<OturumKontrolSayfasi> {
  final ApiService _apiService =
      ApiService();

  late Future<bool> _oturumKontrol;

  @override
  void initState() {
    super.initState();

    _oturumKontrol =
        _apiService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _oturumKontrol,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 70,
                    color: Colors.indigo,
                  ),

                  SizedBox(height: 20),

                  CircularProgressIndicator(),

                  SizedBox(height: 15),

                  Text(
                    'Oturum kontrol ediliyor...',
                  ),
                ],
              ),
            ),
          );
        }

        final girisYapilmis =
            snapshot.data ?? false;

        if (girisYapilmis) {
          return const AnaSayfa();
        }

        return const GirisSayfasi();
      },
    );
  }
}