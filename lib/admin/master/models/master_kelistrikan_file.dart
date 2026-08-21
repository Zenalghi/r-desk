class MasterKelistrikanFile {
  final int id;
  final String pathFile;

  // Tambahkan ID ini untuk keperluan Edit Form
  final int typeEngineId;
  final int merkId;
  final int typeChassisId;

  final String chassisName;
  final String? nomorSut;
  final String merkName;
  final String engineName;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterKelistrikanFile({
    required this.id,
    required this.pathFile,
    required this.typeEngineId, // Baru
    required this.merkId, // Baru
    required this.typeChassisId, // Baru
    required this.chassisName,
    this.nomorSut,
    required this.merkName,
    required this.engineName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MasterKelistrikanFile.fromJson(Map<String, dynamic> json) {
    return MasterKelistrikanFile(
      id: json['id'],
      pathFile: json['path_file'],

      // Ambil ID dari kolom tabel asli
      typeEngineId: json['a_type_engine_id'],
      merkId: json['b_merk_id'],
      typeChassisId: json['c_type_chassis_id'],

      chassisName: () {
        final chassis = json['type_chassis']?.toString() ?? 'Unknown';
        final dagang = json['merek_dagang']?.toString().trim();
        if (dagang != null && dagang.isNotEmpty && dagang != 'null') {
          return '$chassis ($dagang)';
        }
        return chassis;
      }(),
      nomorSut: json['nomor_sut'],
      merkName: json['merk'] ?? '-',
      engineName: json['type_engine'] ?? '-',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
