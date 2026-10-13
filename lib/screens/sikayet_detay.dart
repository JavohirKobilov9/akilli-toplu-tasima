import 'package:flutter/material.dart';

import '../models/complaint_comment.dart';
import '../models/sikayet.dart';
import '../services/api_service.dart';

class SikayetDetaySayfasi extends StatefulWidget {
  final Sikayet sikayet;

  const SikayetDetaySayfasi({
    super.key,
    required this.sikayet,
  });

  @override
  State<SikayetDetaySayfasi> createState() =>
      _SikayetDetaySayfasiState();
}

class _SikayetDetaySayfasiState extends State<SikayetDetaySayfasi> {
  final ApiService _apiService = ApiService();

  final TextEditingController _yorumController = TextEditingController();

  late Future<List<ComplaintComment>> _yorumlar;

  bool _yorumGonderiliyor = false;
  int? _currentUserId;

  final Set<int> _oyIslemiYapilanYorumlar = {};
  final Set<int> _silinenYorumlar = {};

  @override
  void initState() {
    super.initState();

    _yorumlar = _apiService.getComments(
      widget.sikayet.id,
    );

    _kullaniciIdYukle();
  }

  @override
  void dispose() {
    _yorumController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciIdYukle() async {
    try {
      final user = await _apiService.getMe();

      if (!mounted) return;

      setState(() {
        _currentUserId = int.tryParse(
          '${user['id']}',
        );
      });
    } catch (_) {
      // Kullanıcı bilgisi alınamazsa silme butonu gösterilmez.
    }
  }

  void _yorumlariYenile() {
    setState(() {
      _yorumlar = _apiService.getComments(
        widget.sikayet.id,
      );
    });
  }

  Future<void> _yorumGonder() async {
    final yorum = _yorumController.text.trim();

    if (yorum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen bir yorum yazın.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _yorumGonderiliyor = true;
    });

    try {
      await _apiService.addComment(
        complaintId: widget.sikayet.id,
        comment: yorum,
      );

      _yorumController.clear();

      if (!mounted) return;

      _yorumlariYenile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yorum başarıyla eklendi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yorum gönderilemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _yorumGonderiliyor = false;
        });
      }
    }
  }

  Future<void> _oyVer(
    ComplaintComment comment,
    String reaction,
  ) async {
    if (_oyIslemiYapilanYorumlar.contains(comment.id) ||
        _silinenYorumlar.contains(comment.id)) {
      return;
    }

    setState(() {
      _oyIslemiYapilanYorumlar.add(
        comment.id,
      );
    });

    try {
      await _apiService.reactToComment(
        commentId: comment.id,
        reaction: reaction,
      );

      if (!mounted) return;

      _yorumlariYenile();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oy işlemi başarısız: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _oyIslemiYapilanYorumlar.remove(
            comment.id,
          );
        });
      }
    }
  }

  Future<void> _yorumSil(
    ComplaintComment yorum,
  ) async {
    if (_currentUserId != yorum.userId) {
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Yorumu Sil',
          ),
          content: const Text(
            'Bu yorumu silmek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Sil',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    setState(() {
      _silinenYorumlar.add(
        yorum.id,
      );
    });

    try {
      await _apiService.deleteComment(
        yorum.id,
      );

      if (!mounted) return;

      _yorumlariYenile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Yorum başarıyla silindi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yorum silinemedi: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _silinenYorumlar.remove(
            yorum.id,
          );
        });
      }
    }
  }

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'İnceleniyor':
        return Colors.orange;

      case 'Çözüldü':
        return Colors.green;

      default:
        return Colors.blueGrey;
    }
  }

  String _tarihYaz(DateTime? tarih) {
    if (tarih == null) {
      return '';
    }

    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year} '
        '${tarih.hour.toString().padLeft(2, '0')}:'
        '${tarih.minute.toString().padLeft(2, '0')}';
  }

  Widget _yorumKarti(
    ComplaintComment yorum,
  ) {
    final likeAktif = yorum.myReaction == 'like';
    final dislikeAktif = yorum.myReaction == 'dislike';

    final oyIslemiYapiliyor =
        _oyIslemiYapilanYorumlar.contains(yorum.id);

    final siliniyor =
        _silinenYorumlar.contains(yorum.id);

    final kendiYorumu =
        _currentUserId != null && _currentUserId == yorum.userId;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(
                    Icons.person,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yorum.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (yorum.createdAt != null)
                        Text(
                          _tarihYaz(
                            yorum.createdAt,
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (kendiYorumu)
                  IconButton(
                    tooltip: 'Yorumu Sil',
                    onPressed: siliniyor
                        ? null
                        : () {
                            _yorumSil(
                              yorum,
                            );
                          },
                    icon: siliniyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              yorum.comment,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: oyIslemiYapiliyor || siliniyor
                      ? null
                      : () {
                          _oyVer(
                            yorum,
                            'like',
                          );
                        },
                  icon: Icon(
                    likeAktif
                        ? Icons.thumb_up_alt
                        : Icons.thumb_up_alt_outlined,
                    color: likeAktif
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  label: Text(
                    '${yorum.likeCount}',
                    style: TextStyle(
                      color: likeAktif
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: oyIslemiYapiliyor || siliniyor
                      ? null
                      : () {
                          _oyVer(
                            yorum,
                            'dislike',
                          );
                        },
                  icon: Icon(
                    dislikeAktif
                        ? Icons.thumb_down_alt
                        : Icons.thumb_down_alt_outlined,
                    color: dislikeAktif
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  label: Text(
                    '${yorum.dislikeCount}',
                    style: TextStyle(
                      color: dislikeAktif
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ),
                if (oyIslemiYapiliyor) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sikayet = widget.sikayet;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Şikayet Detayı',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _yorumlariYenile();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sikayet.baslik,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _durumRengi(
                              sikayet.durum,
                            ).withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            sikayet.durum,
                            style: TextStyle(
                              color: _durumRengi(
                                sikayet.durum,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sikayet.aciklama,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.category_outlined,
                            size: 18,
                          ),
                          label: Text(
                            sikayet.kategori,
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.directions_bus_outlined,
                            size: 18,
                          ),
                          label: Text(
                            'Hat ${sikayet.hat}',
                          ),
                        ),
                        if (sikayet.durak.isNotEmpty)
                          Chip(
                            avatar: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                            ),
                            label: Text(
                              sikayet.durak,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tarih: '
                      '${sikayet.tarih.day}.'
                      '${sikayet.tarih.month}.'
                      '${sikayet.tarih.year}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                ),
                SizedBox(width: 8),
                Text(
                  'Yorumlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ComplaintComment>>(
              future: _yorumlar,
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Yorumlar yüklenemedi.',
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _yorumlariYenile,
                          child: const Text(
                            'Tekrar Dene',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final yorumlar = snapshot.data ?? [];

                if (yorumlar.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 24,
                    ),
                    child: Center(
                      child: Text(
                        'Henüz yorum yok.\n'
                        'İlk yorumu siz yazabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: yorumlar
                      .map(
                        (yorum) => _yorumKarti(
                          yorum,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Yorum Yaz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _yorumController,
              minLines: 2,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Yorumunuzu yazın...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _yorumGonderiliyor
                    ? null
                    : _yorumGonder,
                icon: _yorumGonderiliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),
                label: Text(
                  _yorumGonderiliyor
                      ? 'Gönderiliyor...'
                      : 'Yorum Gönder',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
