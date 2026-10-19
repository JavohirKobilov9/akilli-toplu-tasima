import 'package:akilli_toplu_tasima/models/sikayet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo metadata survives parsing and serializing', () {
    final complaint = Sikayet.fromJson({
      'id': 42,
      'media_path': 'complaints/photo.jpg',
      'media_type': 'photo',
    });
    expect(complaint.hasMedia, isTrue);
    expect(complaint.isVideo, isFalse);
    expect(complaint.toJson()['media_path'], 'complaints/photo.jpg');
    expect(
      complaint.mediaUri(Uri.parse('http://10.0.2.2:8000/api')).toString(),
      'http://10.0.2.2:8000/api/complaints/42/media',
    );
  });

  test('video metadata and old video records are recognized', () {
    expect(
      Sikayet.fromJson({
        'id': 1,
        'media_path': 'complaints/clip.mp4',
        'media_type': 'video',
      }).isVideo,
      isTrue,
    );
    expect(
      Sikayet.fromJson({'id': 1, 'media_path': 'complaints/clip.MOV'}).isVideo,
      isTrue,
    );
  });

  test('records without attachments do not produce a media URL', () {
    final complaint = Sikayet.fromJson({'id': 1, 'media_path': ' '});
    expect(complaint.hasMedia, isFalse);
    expect(complaint.mediaUri(Uri.parse('https://example.test/api')), isNull);
  });

  test('media cannot point outside the complaint directory', () {
    for (final path in [
      '../secret',
      'complaints/../secret',
      'https://other.test/photo.jpg',
      'complaints/dir\\file.jpg',
    ]) {
      expect(
        Sikayet.fromJson({'id': 1, 'media_path': path})
            .mediaUri(Uri.parse('https://example.test/api')),
        isNull,
      );
    }
  });
}
