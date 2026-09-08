class Surah {
  final int id;
  final String nameAr;
  final String nameTransliteration;
  final String revelationType; // meccan / medinan
  final int totalAyat;

  Surah({
    required this.id,
    required this.nameAr,
    required this.nameTransliteration,
    required this.revelationType,
    required this.totalAyat,
  });

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameTransliteration: map['name_transliteration'] as String? ?? '',
      revelationType: map['revelation_type'] as String? ?? '',
      totalAyat: map['total_ayat'] as int,
    );
  }

  String get revelationTypeAr =>
      revelationType == 'meccan' ? 'مكية' : 'مدنية';
}
