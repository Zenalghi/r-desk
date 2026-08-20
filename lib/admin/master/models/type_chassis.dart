// File: lib/admin/master/models/type_chassis.dart

import 'merk.dart'; // Pastikan import ini ada

class TypeChassis {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sutPdfPath;
  final String? nomorSut;
  final String? merekDagang;
  final String? jenisTipe;

  String get displayName => (merekDagang != null && merekDagang!.trim().isNotEmpty)
      ? '$name (${merekDagang!.trim()})'
      : name;

  // Properti Tambahan (Nested Relation)
  final Merk? merk;

  TypeChassis({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.sutPdfPath,
    this.nomorSut,
    this.merekDagang,
    this.jenisTipe,
    this.merk,
  });

  factory TypeChassis.fromJson(Map<String, dynamic> json) {
    return TypeChassis(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['type_chassis'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sutPdfPath: json['sut_file'] ?? json['sut_pdf_path'],
      nomorSut: json['nomor_sut'],
      merekDagang: json['merek_dagang'],
      jenisTipe: json['jenis_tipe'],
      // Cek apakah ada key 'merk' di dalam JSON chassis
      merk: json['merk'] != null ? Merk.fromJson(json['merk']) : null,
    );
  }
}
