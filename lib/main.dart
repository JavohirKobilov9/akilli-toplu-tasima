import 'package:flutter/material.dart';

import 'screens/giris.dart';
import 'screens/ana_sayfa.dart';
import 'screens/kayit.dart';
import 'screens/sikayet_olustur.dart';
import 'screens/sikayetlerim.dart';
import 'screens/profil.dart';

void main() {
  runApp(const AkilliTopluTasimaApp());
}

class AkilliTopluTasimaApp extends StatelessWidget {
  const AkilliTopluTasimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akilli Toplu Tasima',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      initialRoute: '/giris',
      routes: {
        '/giris': (context) => const GirisSayfasi(),
        '/kayit': (context) => const KayitSayfasi(),
        '/ana': (context) => const AnaSayfa(),
        '/sikayet-olustur': (context) => const SikayetOlusturSayfasi(),
        '/sikayetlerim': (context) => const SikayetlerimSayfasi(),
        '/profil': (context) => const ProfilSayfasi(),
      },
    );
  }
}