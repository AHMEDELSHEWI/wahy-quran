import 'package:flutter/material.dart';

import '../db/quran_database.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حول المصدر والتوثيق')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: QuranDatabase.instance.getProvenanceInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'مصدر النص القرآني',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المصدر: ${r['source_name']}'),
                            const SizedBox(height: 4),
                            Text('الرخصة: ${r['license']}'),
                            const SizedBox(height: 4),
                            Text('مرجع الرسم: ${r['rasm_reference_edition']}'),
                            const SizedBox(height: 4),
                            Text('ملاحظة التحقق: ${r['verification_note']}'),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                const Text(
                  'تنويه مهم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذا إصدار أساسي (Foundation Release) يعرض رواية حفص عن عاصم فقط. '
                  'النص مستورد آليًا من مصدر موثق ومطابق هيكليًا (6236 آية) لكنه '
                  'لم يخضع بعد لمراجعة علمية نهائية من متخصصين قبل الاعتماد '
                  'كإصدار إنتاجي كامل، تماشيًا مع بوابات الجودة المطلوبة لمثل هذه '
                  'التطبيقات.',
                  style: TextStyle(height: 1.6),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
