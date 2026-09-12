import 'package:flutter/material.dart';

import '../db/quran_database.dart';

/// اختيار القراءة (الرواية) — المستخدم يختار بين الروايات المتاحة
/// (حفص، ورش، قالون، الدوري، شعبة...)
class QiraatPickerScreen extends StatefulWidget {
  final String initialQiraat;
  final Function(String selectedQiraat) onQiraatSelected;

  const QiraatPickerScreen({
    super.key,
    this.initialQiraat = 'hafs',
    required this.onQiraatSelected,
  });

  @override
  State<QiraatPickerScreen> createState() => _QiraatPickerScreenState();
}

class _QiraatPickerScreenState extends State<QiraatPickerScreen> {
  late Future<List<Map<String, dynamic>>> _qiraatFuture;
  late String _selectedQiraat;

  @override
  void initState() {
    super.initState();
    _selectedQiraat = widget.initialQiraat;
    _qiraatFuture = QuranDatabase.instance.getAvailableQiraat();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختيار القراءة')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _qiraatFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('خطأ في تحميل الروايات: ${snapshot.error}'),
              );
            }
            final qiraatList = snapshot.data ?? [];
            return ListView.separated(
              itemCount: qiraatList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final qiraat = qiraatList[index];
                final qiraatId = qiraat['id'] as String;
                final nameAr = qiraat['name_ar'] as String;
                final nameEn = qiraat['name_en'] as String;
                final description =
                    (qiraat['description'] as String?) ?? nameEn;

                return RadioListTile<String>(
                  title: Text(
                    nameAr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(description),
                  value: qiraatId,
                  groupValue: _selectedQiraat,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedQiraat = value);
                    }
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            widget.onQiraatSelected(_selectedQiraat);
            Navigator.pop(context, _selectedQiraat);
          },
          icon: const Icon(Icons.check),
          label: const Text('تأكيد'),
        ),
      ),
    );
  }
}
