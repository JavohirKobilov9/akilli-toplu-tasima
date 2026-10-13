import 'package:flutter/material.dart';

import '../models/sikayet.dart';
import '../services/api_service.dart';
import 'sikayet_detay.dart';

class SikayetlerimSayfasi
    extends StatefulWidget {
  const SikayetlerimSayfasi({
    super.key,
  });

  @override
  State<SikayetlerimSayfasi>
      createState() =>
          _SikayetlerimSayfasiState();
}

class _SikayetlerimSayfasiState
    extends State<SikayetlerimSayfasi> {
  final ApiService _apiService =
      ApiService();

  late Future<List<Sikayet>> _sikayetler;

  @override
  void initState() {
    super.initState();

    _sikayetler =
        _apiService.getMyComplaints();
  }

  void _yenile() {
    setState(() {
      _sikayetler =
          _apiService.getMyComplaints();
    });
  }

  Future<void> _detayaGit(
    Sikayet sikayet,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SikayetDetaySayfasi(
          sikayet: sikayet,
        ),
      ),
    );

    if (!mounted) return;

    _yenile();
  }

  Future<void> _sikayetSil(
    Sikayet sikayet,
  ) async {
    final onay =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Şikayeti Sil'),
          content: const Text(
            'Bu şikayeti silmek istediğinizden '
            'emin misiniz?\n\n'
            'Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    try {
      await _apiService
          .deleteComplaint(
        sikayet.id,
      );

      if (!mounted) return;

      _yenile();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Şikayet başarıyla silindi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Şikayet silinemedi: $e',
          ),
        ),
      );
    }
  }

  Color _durumRengi(
    String durum,
  ) {
    switch (durum) {
      case 'İnceleniyor':
        return Colors.orange;

      case 'Çözüldü':
        return Colors.green;

      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Şikayetlerim'),
        actions: [
          IconButton(
            onPressed: _yenile,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          FutureBuilder<List<Sikayet>>(
        future: _sikayetler,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Şikayetler yüklenirken hata oluştu.',
              ),
            );
          }

          final sikayetler =
              snapshot.data ?? [];

          if (sikayetler.isEmpty) {
            return const Center(
              child: Text(
                'Henüz şikayetiniz bulunmuyor.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _yenile();
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  sikayetler.length,
              itemBuilder: (
                context,
                index,
              ) {
                final sikayet =
                    sikayetler[index];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 14,
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _detayaGit(
                        sikayet,
                      );
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sikayet.baslik,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      10,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      _durumRengi(
                                    sikayet
                                        .durum,
                                  ).withValues(
                                    alpha:
                                        0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  sikayet.durum,
                                  style:
                                      TextStyle(
                                    color:
                                        _durumRengi(
                                      sikayet
                                          .durum,
                                    ),
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            sikayet.aciklama,
                            maxLines: 3,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  sikayet
                                      .kategori,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Hat ${sikayet.hat}',
                                ),
                              ),
                              if (sikayet
                                  .durak
                                  .isNotEmpty)
                                Chip(
                                  label: Text(
                                    sikayet
                                        .durak,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tarih: '
                                  '${sikayet.tarih.day}.'
                                  '${sikayet.tarih.month}.'
                                  '${sikayet.tarih.year}',
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        12,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),

                              TextButton.icon(
                                onPressed: () {
                                  _sikayetSil(
                                    sikayet,
                                  );
                                },
                                icon: const Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                      Colors.red,
                                ),
                                label:
                                    const Text(
                                  'Sil',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}