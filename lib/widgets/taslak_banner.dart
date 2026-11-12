import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/draft_service.dart';

/// İnternet yokken kaydedilen şikayet taslaklarını gösterir ve gönderir.
class TaslakBanner extends StatefulWidget {
  /// Taslaklar gönderildiğinde şikayet listesini yenilemek için.
  final VoidCallback? onSent;

  const TaslakBanner({super.key, this.onSent});

  @override
  State<TaslakBanner> createState() => _TaslakBannerState();
}

class _TaslakBannerState extends State<TaslakBanner> {
  final DraftService _drafts = DraftService();
  final ApiService _api = ApiService();

  List<ComplaintDraft> _items = [];
  bool _sending = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _drafts.all();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _sendAll() async {
    setState(() {
      _sending = true;
      _message = null;
    });

    var sent = 0;
    String? error;

    for (final draft in List.of(_items)) {
      try {
        final media = draft.mediaPath;
        // Geçici dosya silinmişse şikayet fotoğrafsız gönderilir.
        final mediaExists = media != null && File(media).existsSync();
        await _api.sikayetOlustur(
          baslik: draft.baslik,
          kategori: draft.kategori,
          aciklama: draft.aciklama,
          lineId: draft.lineId,
          stopId: draft.stopId,
          latitude: draft.latitude,
          longitude: draft.longitude,
          mediaPath: mediaExists ? media : null,
        );
        await _drafts.remove(draft.id);
        sent++;
      } catch (e) {
        error = DraftService.isNetworkError(e)
            ? 'İnternet bağlantısı yok. Bağlantı gelince tekrar deneyin.'
            : e.toString().replaceFirst('Exception: ', '');
        break;
      }
    }

    await _load();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _message = error ??
          (sent > 0 ? '$sent taslak gönderildi.' : null);
    });
    if (sent > 0) widget.onSent?.call();
  }

  Future<void> _delete(ComplaintDraft draft) async {
    await _drafts.remove(draft.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _message == null) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_items.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.cloud_off),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_items.length} şikayet taslağı gönderilmeyi bekliyor',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton(
                    onPressed: _sending ? null : _sendAll,
                    child: Text(_sending ? 'Gönderiliyor…' : 'Şimdi gönder'),
                  ),
                ],
              ),
            for (final draft in _items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  draft.baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(draft.kategori),
                trailing: IconButton(
                  tooltip: 'Taslağı sil',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _sending ? null : () => _delete(draft),
                ),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_message!),
              ),
          ],
        ),
      ),
    );
  }
}
