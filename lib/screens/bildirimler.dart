import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';
import 'sikayet_detay.dart';

class BildirimlerSayfasi extends StatefulWidget {
  const BildirimlerSayfasi({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<BildirimlerSayfasi> createState() => _BildirimlerSayfasiState();
}

class _BildirimlerSayfasiState extends State<BildirimlerSayfasi> {
  late final ApiService _api;
  final List<AppNotification> _items = [];
  bool _loading = false;
  bool _hasMore = false;
  int _page = 0;
  int? _openingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nextPage = reset ? 1 : _page + 1;
      final result = await _api.getNotifications(page: nextPage);
      final pagination = result['data'] as Map<String, dynamic>;
      final rows = (pagination['data'] as List)
          .map((row) => AppNotification.fromJson(row as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(rows);
        _page = nextPage;
        _hasMore = pagination['next_page_url'] != null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Bildirimler yüklenemedi. Yeniden deneyin.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (_openingId != null) return;
    setState(() => _openingId = item.id);
    try {
      await _api.markNotificationRead(item.id);
      if (item.complaintId == null) {
        throw Exception('Bu şikayet artık mevcut değil.');
      }
      final complaint = await _api.getComplaint(item.complaintId!);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SikayetDetaySayfasi(sikayet: complaint),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingId = null);
        await _load(reset: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Bildirimler'),
      actions: [
        IconButton(
          onPressed: _loading ? null : () => _load(reset: true),
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_items.isEmpty && !_loading && _error == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Henüz bildiriminiz yok. Şikayetinizin durumu değiştiğinde burada görebilirsiniz.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final item in _items)
            Card(
              color: item.isRead
                  ? null
                  : Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(
                  item.status == 'Çözüldü'
                      ? Icons.check_circle_outline
                      : Icons.notifications_active_outlined,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${item.message}\n${item.createdAt == null ? '' : _date(item.createdAt!)}',
                ),
                isThreeLine: true,
                trailing: _openingId == item.id
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _open(item),
              ),
            ),
          if (_error != null) Text(_error!, textAlign: TextAlign.center),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!_loading && (_hasMore || _error != null))
            TextButton(
              onPressed: () => _load(reset: _page == 0),
              child: Text(
                _error != null ? 'Yeniden Dene' : 'Daha Fazla Göster',
              ),
            ),
        ],
      ),
    ),
  );

  String _date(DateTime date) =>
      '${date.day}.${date.month}.${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
