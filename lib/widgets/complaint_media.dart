import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../models/sikayet.dart';
import '../services/api_service.dart';

class ComplaintMedia extends StatefulWidget {
  const ComplaintMedia({super.key, required this.complaint});

  final Sikayet complaint;

  @override
  State<ComplaintMedia> createState() => _ComplaintMediaState();
}

class _ComplaintMediaState extends State<ComplaintMedia> {
  late final Future<String?> _token = ApiService().getToken();

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    if (!complaint.hasMedia) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Text('Ek dosyayı görmek için giriş yapın.');
        }
        return _AuthenticatedMedia(
          complaint: complaint,
          headers: {'Authorization': 'Bearer ${snapshot.data}'},
        );
      },
    );
  }
}

class _AuthenticatedMedia extends StatelessWidget {
  const _AuthenticatedMedia({required this.complaint, required this.headers});
  final Sikayet complaint;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final uri = complaint.mediaUri(Uri.parse(ApiService().baseUrl));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Eklenen ${complaint.isVideo ? 'Video' : 'Fotoğraf'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (uri == null)
              const Text('Ek dosyanın adresi geçersiz.')
            else if (complaint.isVideo)
              _ComplaintVideo(key: ValueKey(uri), uri: uri, headers: headers)
            else ...[
              _ComplaintPhoto(key: ValueKey(uri), uri: uri, headers: headers),
              const SizedBox(height: 8),
              const Text('Büyütmek için fotoğrafa dokunun.'),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _photo(Uint8List bytes, {double? height}) => Image.memory(
  bytes,
  height: height,
  width: double.infinity,
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) => SizedBox(
    height: 140,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_outlined, size: 36),
        const SizedBox(height: 8),
        const Text(
          'Fotoğraf yüklenemedi. Dosya yalnızca şikayet sahibi ve yöneticiler tarafından görüntülenebilir.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Şikayet Fotoğrafı')),
    body: Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: _photo(bytes),
      ),
    ),
  );
}

class _ComplaintPhoto extends StatefulWidget {
  const _ComplaintPhoto({super.key, required this.uri, required this.headers});
  final Uri uri;
  final Map<String, String> headers;

  @override
  State<_ComplaintPhoto> createState() => _ComplaintPhotoState();
}

class _ComplaintPhotoState extends State<_ComplaintPhoto> {
  final _client = http.Client();
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  Future<Uint8List> _load() async {
    // Her oturumda sunucudan yetki kontrolü yapılır; URL tabanlı ortak resim önbelleği kullanılmaz.
    final response = await _client
        .get(widget.uri, headers: widget.headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 403) {
      throw Exception(
        'Bu dosyayı yalnızca şikayet sahibi ve yöneticiler görüntüleyebilir.',
      );
    }
    if (response.statusCode == 404) {
      throw Exception('Fotoğraf artık mevcut değil.');
    }
    if (response.statusCode != 200) {
      throw Exception('Fotoğraf yüklenemedi. Lütfen yeniden deneyin.');
    }
    return response.bodyBytes;
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        return Column(
          children: [
            Text(
              error is Exception
                  ? error.toString().replaceFirst('Exception: ', '')
                  : 'Fotoğraf yüklenemedi.',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => setState(() => _bytes = _load()),
              child: const Text('Yeniden Dene'),
            ),
          ],
        );
      }
      return Semantics(
        button: true,
        label: 'Şikayet fotoğrafını büyüt',
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => _PhotoViewer(bytes: snapshot.data!),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _photo(snapshot.data!, height: 240),
          ),
        ),
      );
    },
  );
}

class _ComplaintVideo extends StatefulWidget {
  const _ComplaintVideo({super.key, required this.uri, required this.headers});
  final Uri uri;
  final Map<String, String> headers;

  @override
  State<_ComplaintVideo> createState() => _ComplaintVideoState();
}

class _ComplaintVideoState extends State<_ComplaintVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _error = false;

  bool get _supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) _controller?.pause();
  }

  Future<void> _play() async {
    if (_loading) return;
    if (!_supported) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    final previous = _controller;
    final controller = VideoPlayerController.networkUrl(
      widget.uri,
      httpHeaders: widget.headers,
    );
    _controller = controller;
    await previous?.dispose();
    try {
      await controller.initialize().timeout(const Duration(seconds: 25));
      if (!mounted || _controller != controller) return;
      await controller.play();
    } catch (_) {
      if (mounted && _controller == controller) setState(() => _error = true);
    } finally {
      if (mounted && _controller == controller) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error) {
      return Column(
        children: [
          const Text(
            'Video oynatılamadı. Dosyaya erişim yetkinizi, bağlantıyı veya dosya biçimini kontrol edin.',
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _play, child: const Text('Yeniden Dene')),
        ],
      );
    }
    if (controller == null) {
      if (!_supported) {
        return const Text(
          'Korumalı videoları Android veya iOS uygulamasında görüntüleyebilirsiniz.',
        );
      }
      return FilledButton.icon(
        onPressed: _play,
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Videoyu Oynat'),
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.hasError) {
          return Column(
            children: [
              const Text(
                'Video oynatılırken bağlantı kesildi veya dosya desteklenmiyor.',
              ),
              TextButton(onPressed: _play, child: const Text('Yeniden Dene')),
            ],
          );
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  if (value.isBuffering) const CircularProgressIndicator(),
                ],
              ),
            ),
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: value.isPlaying ? 'Duraklat' : 'Oynat',
                  onPressed: () async {
                    try {
                      if (value.isPlaying) {
                        await controller.pause();
                      } else {
                        if (value.position >= value.duration) {
                          await controller.seekTo(Duration.zero);
                        }
                        await controller.play();
                      }
                    } catch (_) {
                      if (mounted) setState(() => _error = true);
                    }
                  },
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Text(
                    '${_time(value.position)} / ${_time(value.duration)}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _time(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}
