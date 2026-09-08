class Ayah {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String textUthmani;
  final String riwayah;
  final String sourcePrimary;
  final String sourceRasmReference;
  final String verificationStatus;

  Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.textUthmani,
    required this.riwayah,
    required this.sourcePrimary,
    required this.sourceRasmReference,
    required this.verificationStatus,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      textUthmani: map['text_uthmani'] as String,
      riwayah: map['riwayah'] as String? ?? 'hafs_an_asim',
      sourcePrimary: map['source_primary'] as String? ?? 'tanzil_uthmani',
      sourceRasmReference:
          map['source_rasm_reference'] as String? ?? 'madinah_mushaf_1405h',
      verificationStatus: map['verification_status'] as String? ??
          'auto_imported_pending_scholar_review',
    );
  }

  /// Human-readable Arabic label for the riwayah (currently only Hafs is loaded).
  String get riwayahAr {
    switch (riwayah) {
      case 'hafs_an_asim':
        return 'حفص عن عاصم';
      default:
        return riwayah;
    }
  }
}
