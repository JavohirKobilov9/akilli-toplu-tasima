import 'package:akilli_toplu_tasima/services/draft_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ComplaintDraft _draft(String id) => ComplaintDraft(
      id: id,
      baslik: 'Otobüs geç geldi',
      kategori: 'Sefer Gecikmesi',
      aciklama: 'Otobüs duraktan yirmi dakika geç geldi.',
      lineId: 3,
      stopId: 7,
      latitude: 41.635,
      longitude: 32.337,
      mediaPath: '/tmp/foto.jpg',
      createdAt: DateTime(2026, 11, 12, 10, 30),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('draft survives save and load', () async {
    final service = DraftService();
    await service.save(_draft('1'));

    final loaded = await service.all();

    expect(loaded, hasLength(1));
    expect(loaded.single.baslik, 'Otobüs geç geldi');
    expect(loaded.single.lineId, 3);
    expect(loaded.single.stopId, 7);
    expect(loaded.single.latitude, 41.635);
    expect(loaded.single.mediaPath, '/tmp/foto.jpg');
  });

  test('remove deletes only the chosen draft', () async {
    final service = DraftService();
    await service.save(_draft('1'));
    await service.save(_draft('2'));

    await service.remove('1');

    final loaded = await service.all();
    expect(loaded.map((d) => d.id), ['2']);
  });

  test('corrupt entries are ignored', () async {
    SharedPreferences.setMockInitialValues({
      'complaint_drafts': ['not json'],
    });

    expect(await DraftService().all(), isEmpty);
  });

  test('network errors are recognised, validation errors are not', () {
    expect(
      DraftService.isNetworkError(Exception('SocketException: Failed host lookup')),
      isTrue,
    );
    expect(DraftService.isNetworkError(Exception('TimeoutException after 0:00:15')), isTrue);
    expect(
      DraftService.isNetworkError(Exception('Şikayet metninde uygun olmayan ifadeler (HTTP 422)')),
      isFalse,
    );
  });
}
