import 'package:flutter/material.dart';

import 'dart:async';

import '../services/api_service.dart';
import '../services/push_notification_service.dart';

import 'harita.dart';
import 'sefer_saatleri.dart';
import 'topluluk_sikayetleri.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with WidgetsBindingObserver {
  int _seciliIndex = 0;
  int _unreadCount = 0;
  bool _checkingNotifications = false;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotificationService.instance.changes.addListener(_refreshNotifications);
    _refreshNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PushNotificationService.instance.start();
    });
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refreshNotifications();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotifications();
      PushNotificationService.instance.start();
    }
  }

  Future<void> _refreshNotifications() async {
    if (_checkingNotifications) return;
    _checkingNotifications = true;
    try {
      final result = await ApiService().getNotifications();
      if (mounted) setState(() => _unreadCount = result['unread_count'] as int);
    } catch (_) {
      // Liste ekranı bağlantı hatasında yeniden deneme sunar.
    } finally {
      _checkingNotifications = false;
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    PushNotificationService.instance.changes.removeListener(
      _refreshNotifications,
    );
    super.dispose();
  }

  Future<void> _sayfaDegistir(int index) async {
    if (index == 0) {
      setState(() {
        _seciliIndex = 0;
      });
      return;
    }

    if (index == 1) {
      setState(() {
        _seciliIndex = 1;
      });

      await Navigator.pushNamed(context, '/sikayetlerim');

      if (!mounted) return;

      setState(() {
        _seciliIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Akıllı Toplu Taşıma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            onPressed: () async {
              await Navigator.pushNamed(context, '/bildirimler');
              if (mounted) _refreshNotifications();
            },
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () {
              Navigator.pushNamed(context, '/profil');
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.directions_bus, size: 48, color: Colors.white),

                  SizedBox(height: 16),

                  Text(
                    'Toplu taşıma deneyimini\n'
                    'birlikte iyileştirelim.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Yaşadığın sorunları bildir, '
                    'şehir içi ulaşımın '
                    'geliştirilmesine katkı sağla.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Ne yapmak istiyorsun?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // ŞİKAYET OLUŞTUR
            _MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Şikayet Oluştur',
              description: 'Yaşadığın ulaşım sorununu bildir.',
              onTap: () {
                Navigator.pushNamed(context, '/sikayet-olustur');
              },
            ),

            const SizedBox(height: 12),

            // BENİM ŞİKAYETLERİM
            _MenuCard(
              icon: Icons.list_alt,
              title: 'Şikayetlerim',
              description:
                  'Sadece kendi gönderdiğin '
                  'şikayetleri görüntüle.',
              onTap: () {
                Navigator.pushNamed(context, '/sikayetlerim');
              },
            ),

            const SizedBox(height: 12),

            // TOPLULUK ŞİKAYETLERİ
            _MenuCard(
              icon: Icons.groups_outlined,
              title: 'Topluluk Şikayetleri',
              description:
                  'Diğer kullanıcıların '
                  'şikayetlerini gör, yorum yap '
                  've beğen.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ToplulukSikayetleriSayfasi(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // SEFER SAATLERİ
            _MenuCard(
              icon: Icons.schedule_outlined,
              title: 'Sefer Saatleri',
              description:
                  'Bartın güzergahlarının sefer '
                  'saatlerini görüntüle.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeferSaatleriSayfasi(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ŞİKAYET HARİTASI
            _MenuCard(
              icon: Icons.map_outlined,
              title: 'Şikayet Haritası',
              description:
                  'Konumlu şikayetleri harita '
                  'üzerinde görüntüle.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HaritaScreen()),
                );
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliIndex,
        onDestinationSelected: _sayfaDegistir,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Şikayetlerim',
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.indigo, size: 30),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
