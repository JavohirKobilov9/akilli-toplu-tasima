import 'package:akilli_toplu_tasima/models/sikayet.dart';
import 'package:akilli_toplu_tasima/screens/bildirimler.dart';
import 'package:akilli_toplu_tasima/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationApi extends ApiService {
  bool fail = false;
  bool includeNotification = false;
  bool read = false;

  @override
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    if (fail) throw Exception('offline');
    return {
      'unread_count': includeNotification && !read ? 1 : 0,
      'data': {
        'next_page_url': null,
        'data': [
          if (includeNotification)
            {
              'id': 1,
              'complaint_id': 4,
              'title': 'Şikayetinizin durumu güncellendi',
              'message': 'Gecikme şikayetiniz: Çözüldü.',
              'status': 'Çözüldü',
              'read_at': read ? '2026-10-17T10:00:00Z' : null,
              'created_at': '2026-10-17T09:00:00Z',
            },
        ],
      },
    };
  }

  @override
  Future<void> markNotificationRead(int id) async {
    read = true;
  }

  @override
  Future<Sikayet> getComplaint(int id) async {
    throw Exception('Bu şikayet artık mevcut değil.');
  }
}

void main() {
  testWidgets('empty inbox explains when notifications appear', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BildirimlerSayfasi(apiService: FakeNotificationApi())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz bildiriminiz yok.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed loading can be retried without restarting the screen', (tester) async {
    final api = FakeNotificationApi()..fail = true;
    await tester.pumpWidget(MaterialApp(home: BildirimlerSayfasi(apiService: api)));
    await tester.pumpAndSettle();
    expect(find.text('Bildirimler yüklenemedi. Yeniden deneyin.'), findsOneWidget);
    api.fail = false;
    api.includeNotification = true;
    await tester.tap(find.text('Yeniden Dene'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gecikme şikayetiniz: Çözüldü.'), findsOneWidget);
    expect(find.text('Bildirimler yüklenemedi. Yeniden deneyin.'), findsNothing);
  });

  testWidgets('deleted complaint notification is read and shows an explanation', (tester) async {
    final api = FakeNotificationApi()..includeNotification = true;
    await tester.pumpWidget(MaterialApp(home: BildirimlerSayfasi(apiService: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Şikayetinizin durumu güncellendi'));
    await tester.pumpAndSettle();
    expect(api.read, isTrue);
    expect(find.text('Bu şikayet artık mevcut değil.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
