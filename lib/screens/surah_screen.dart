import 'package:flutter/material.dart';

import '../db/quran_database.dart';
import '../models/ayah.dart';
import '../models/surah.dart';
import '../widgets/ayah_tile.dart';

class SurahScreen extends StatefulWidget {
  final int surahId;
  const SurahScreen({super.key, required this.surahId});

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late Future<_SurahData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_SurahData> _load() async {
    final surah = await QuranDatabase.instance.getSurahById(widget.surahId);
    final ayat = await QuranDatabase.instance.getAyatBySurah(widget.surahId);
    return _SurahData(surah: surah, ayat: ayat);
  }

  void _showAyahDetails(Ayah ayah) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الآية ${ayah.ayahNumber}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('الرواية: ${ayah.riwayahAr}'),
              Text('مرجع الرسم: مصحف المدينة النبوية (طبعة 1405هـ)'),
              const SizedBox(height: 4),
              Text(
                'حالة التحقق: ${ayah.verificationStatus == "auto_imported_pending_scholar_review" ? "مستوردة آليًا — بانتظار مراجعة علمية نهائية" : ayah.verificationStatus}',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<_SurahData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.surah?.nameAr ?? '...';
              return Text(name);
            },
          ),
        ),
        body: FutureBuilder<_SurahData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            }
            final ayat = snapshot.data!.ayat;
            final showBasmalah = widget.surahId != 1 && widget.surahId != 9;
            return Column(
              children: [
                if (showBasmalah)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontFamily: 'AmiriQuran',
                          ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      children: ayat
                          .map((a) => AyahTile(
                                ayah: a,
                                onLongPress: () => _showAyahDetails(a),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SurahData {
  final Surah? surah;
  final List<Ayah> ayat;
  _SurahData({required this.surah, required this.ayat});
}
