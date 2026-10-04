import 'package:flutter/material.dart';

class ProfilSayfasi extends StatelessWidget {
  const ProfilSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 55,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Kullanıcı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'kullanici@example.com',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                    ),
                    title: const Text('Hesap Bilgileri'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () {},
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.notifications_none,
                    ),
                    title: const Text('Bildirimler'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                    ),
                    title: const Text('Hakkında'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName:
                            'Akıllı Toplu Taşıma',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Üniversite proje çalışması',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/giris',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}