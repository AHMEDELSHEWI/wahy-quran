import 'dart:async';
import 'package:flutter/material.dart';

import '../db/quran_database.dart';
import '../models/ayah.dart';
import 'surah_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Ayah> _results = [];
  bool _loading = false;
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final results = await QuranDatabase.instance.searchAyat(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'ابحث في آيات القرآن الكريم...',
              border: InputBorder.none,
            ),
            onChanged: _onChanged,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? 'اكتب كلمة للبحث عنها في القرآن الكريم'
                          : 'لا توجد نتائج',
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ayah = _results[index];
                      return ListTile(
                        title: Text(
                          ayah.textUthmani,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                            'سورة رقم ${ayah.surahId} - الآية ${
