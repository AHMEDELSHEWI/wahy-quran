import 'package:flutter/material.dart';

import '../db/quran_database.dart';
import '../models/surah.dart';
import 'surah_screen.dart';
import 'search_screen.dart';
import 'about_screen.dart';
import 'mushaf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Surah>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = QuranDatabase.instance.getAllSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('وحي — المصحف الشريف'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'بحث',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'حول المصدر والتوثيق',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
          ],
        ),
        body: FutureBuilder<List<Surah>>(
          future: _surahsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              );
            }
            final surahs = snapshot.data ?? [];
            return ListView.separated(
              itemCount: surahs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${surah.id}')),
                  title: Text(
                    surah.nameAr,
                    style: const TextStyle(fontSize: 18),
                  ),
                  subtitle: Text(
                    '${surah.revelationTypeAr} • ${surah.totalAyat} آية',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SurahScreen(surahId: surah.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MushafViewerScreen()),
            );
          },
          icon: const Icon(Icons.menu_book),
          label: const Text('فتح المصحف'),
        ),
      ),
    );
  }
}
