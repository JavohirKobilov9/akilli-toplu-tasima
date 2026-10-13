import 'package:flutter/material.dart';

import '../models/sikayet.dart';
import '../services/api_service.dart';
import 'sikayet_detay.dart';

class ToplulukSikayetleriSayfasi
    extends StatefulWidget {
  const ToplulukSikayetleriSayfasi({
    super.key,
  });

  @override
  State<ToplulukSikayetleriSayfasi>
      createState() =>
          _ToplulukSikayetleriSayfasiState();
}

class _ToplulukSikayetleriSayfasiState
    extends State<ToplulukSikayetleriSayfasi> {
  final ApiService _apiService = ApiService();

  late Future<List<Sikayet>> _sikayetler;

  @override
  void initState() {
    super.initState();
    _sikayetler = _apiService.getSikayetler();
  }

  void _yenile() {
    setState(() {
      _sikayetler = _apiService.getSikayetler();
    });
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

  void _detayaGit(Sikayet sikayet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SikayetDetaySayfasi(
          sikayet: sikayet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Topluluk Şikayetleri',
        ),
        actions: [
          IconButton(
            onPressed: _yenile,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Sikayet>>(
        future: _sikayetler,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Şikayetler yüklenemedi.\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final sikayetler =
              snapshot.data ?? [];

          if (sikayetler.isEmpty) {
            return const Center(
              child: Text(
                'Henüz topluluk şikayeti yok.',
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
              itemCount: sikayetler.length,
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
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      _durumRengi(
                                    sikayet.durum,
                                  ).withValues(
                                    alpha: 0.12,
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
                                      sikayet.durum,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 12,
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
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar:
                                    const Icon(
                                  Icons
                                      .category_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  sikayet.kategori,
                                ),
                              ),
                              Chip(
                                avatar:
                                    const Icon(
                                  Icons
                                      .directions_bus_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'Hat ${sikayet.hat}',
                                ),
                              ),
                              Chip(
                                avatar:
                                    const Icon(
                                  Icons
                                      .location_on_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  sikayet.durak,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons
                                    .forum_outlined,
                                size: 17,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Yorumlar ve '
                                '👍 / 👎',
                                style: TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                              Icon(
                                Icons
                                    .chevron_right,
                                color: Colors.grey,
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