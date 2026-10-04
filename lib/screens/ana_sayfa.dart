import 'package:flutter/material.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndex = 0;

  void _sayfaDegistir(int index) {
    setState(() {
      _seciliIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/sikayetlerim');
    }

    if (index == 2) {
      Navigator.pushNamed(context, '/profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Akıllı Toplu Taşıma',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
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
                  Icon(
                    Icons.directions_bus,
                    size: 48,
                    color: Colors.white,
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Toplu taşıma deneyimini\nbirlikte iyileştirelim.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Yaşadığın sorunları bildir, şehir içi ulaşımın geliştirilmesine katkı sağla.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Ne yapmak istiyorsun?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Şikayet Oluştur',
              description: 'Yaşadığın ulaşım sorununu bildir.',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/sikayet-olustur',
                );
              },
            ),

            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.list_alt,
              title: 'Şikayetlerim',
              description: 'Gönderdiğin şikayetleri görüntüle.',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/sikayetlerim',
                );
              },
            ),

            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.person_outline,
              title: 'Profil',
              description: 'Hesap bilgilerini görüntüle.',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profil',
                );
              },
            ),
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
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
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
                child: Icon(
                  icon,
                  color: Colors.indigo,
                  size: 30,
                ),
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
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
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