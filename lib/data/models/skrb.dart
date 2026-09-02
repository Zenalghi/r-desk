// File: lib/data/models/skrb.dart

class SkrbHistoryItem {
  final int id;
  final int skrbId;
  final String fileName;
  final String storagePath;
  final int fileSize;
  final String createdAt;

  SkrbHistoryItem({
    required this.id,
    required this.skrbId,
    required this.fileName,
    required this.storagePath,
    required this.fileSize,
    required this.createdAt,
  });

  factory SkrbHistoryItem.fromJson(Map<String, dynamic> json) {
    return SkrbHistoryItem(
      id: json['id'] ?? 0,
      skrbId: int.tryParse('${json['skrb_id']}') ?? 0,
      fileName: json['file_name'] ?? '',
      storagePath: json['storage_path'] ?? '',
      fileSize: int.tryParse('${json['file_size']}') ?? 0,
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}

class SkrbAvailableTransaction {
  final String id;
  final int? customerId;
  final int? masterDataId;
  final int? jenisPengajuanId;
  final String customerName;
  final String typeEngine;
  final String merk;
  final String typeChassis;
  final String? merekDagang;
  final String jenisKendaraan;
  final String jenisPengajuan;
  final String? nomorSut;

  String get chassisDisplayName => (merekDagang != null && merekDagang!.trim().isNotEmpty)
      ? '$typeChassis (${merekDagang!.trim()})'
      : typeChassis;

  SkrbAvailableTransaction({
    required this.id,
    this.customerId,
    this.masterDataId,
    this.jenisPengajuanId,
    required this.customerName,
    required this.typeEngine,
    required this.merk,
    required this.typeChassis,
    this.merekDagang,
    required this.jenisKendaraan,
    required this.jenisPengajuan,
    this.nomorSut,
  });

  factory SkrbAvailableTransaction.fromJson(Map<String, dynamic> json) {
    return SkrbAvailableTransaction(
      id: '${json['id'] ?? ''}',
      customerId: int.tryParse('${json['customer_id']}'),
      masterDataId: int.tryParse('${json['master_data_id']}'),
      jenisPengajuanId: int.tryParse('${json['jenis_pengajuan_id']}'),
      customerName: json['customer_name'] ?? '-',
      typeEngine: json['type_engine'] ?? '-',
      merk: json['merk'] ?? '-',
      typeChassis: json['type_chassis'] ?? '-',
      merekDagang: json['merek_dagang']?.toString(),
      jenisKendaraan: json['jenis_kendaraan'] ?? '-',
      jenisPengajuan: json['jenis_pengajuan'] ?? 'Varian',
      nomorSut: json['nomor_sut']?.toString(),
    );
  }

  @override
  String toString() => '$id - $customerName ($merk / $chassisDisplayName)';
}

class Skrb {
  final int id;
  final String idSkrb;
  final String transaksiId;
  final int? customerId;
  final int? masterDataId;
  final int? jenisPengajuanId;
  final String customerName;
  final String typeEngine;
  final String merk;
  final String typeChassis;
  final String? merekDagang;
  final String jenisKendaraan;
  final String jenisPengajuan;
  final String statusTdp;
  final int? documentCustomerId;
  final bool hasDocumentCustomer;
  final String? nomorSut;

  String get chassisDisplayName => (merekDagang != null && merekDagang!.trim().isNotEmpty)
      ? '$typeChassis (${merekDagang!.trim()})'
      : typeChassis;
  final String? tdpMasaBerlaku;
  final bool isTdpOutdated;
  final bool hasKopSurat;
  final String kopSource;
  final int fase;
  final String? fotoCopySkrb;
  final String? tanggalPermohonan;
  final String? suggestedFileName;
  final Map<String, dynamic> customFiles;
  final Map<String, dynamic> hiddenFlags;
  final Map<String, dynamic> snapshotDocuments;
  final List<SkrbHistoryItem> histories;
  final String createdAt;
  final String updatedAt;
  final bool alreadyExists;

  Skrb({
    required this.id,
    required this.idSkrb,
    required this.transaksiId,
    this.customerId,
    this.masterDataId,
    this.jenisPengajuanId,
    required this.customerName,
    required this.typeEngine,
    required this.merk,
    required this.typeChassis,
    this.merekDagang,
    required this.jenisKendaraan,
    required this.jenisPengajuan,
    required this.statusTdp,
    this.documentCustomerId,
    this.hasDocumentCustomer = false,
    this.nomorSut,
    this.tdpMasaBerlaku,
    this.isTdpOutdated = false,
    this.hasKopSurat = true,
    this.kopSource = 'customer',
    required this.fase,
    this.fotoCopySkrb,
    this.tanggalPermohonan,
    this.suggestedFileName,
    required this.customFiles,
    required this.hiddenFlags,
    required this.snapshotDocuments,
    required this.histories,
    required this.createdAt,
    required this.updatedAt,
    this.alreadyExists = false,
  });

  factory Skrb.fromJson(Map<String, dynamic> json) {
    var histList = <SkrbHistoryItem>[];
    if (json['histories'] != null && json['histories'] is List) {
      histList = (json['histories'] as List)
          .map((h) => SkrbHistoryItem.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    final docId = json['document_customer_id'] != null
        ? int.tryParse(json['document_customer_id'].toString())
        : (json['snapshot_documents'] != null && json['snapshot_documents'] is Map
            ? int.tryParse('${json['snapshot_documents']['document_customer_id']}')
            : null);

    final hasDocCustomer = json['has_document_customer'] == true ||
        docId != null ||
        (json['snapshot_documents'] != null &&
            json['snapshot_documents'] is Map &&
            (json['snapshot_documents']['data_umum_file'] != null ||
                json['snapshot_documents']['kop_surat_file'] != null ||
                json['snapshot_documents']['alamat_permohonan'] != null));

    return Skrb(
      id: json['id'] ?? 0,
      idSkrb: json['id_skrb'] ?? '',
      transaksiId: '${json['transaksi_id'] ?? ''}',
      customerId: int.tryParse('${json['customer_id']}'),
      masterDataId: int.tryParse('${json['master_data_id']}'),
      jenisPengajuanId: int.tryParse('${json['jenis_pengajuan_id']}'),
      customerName: json['customer_name'] ?? '-',
      typeEngine: json['type_engine'] ?? '-',
      merk: json['merk'] ?? '-',
      typeChassis: json['type_chassis'] ?? '-',
      merekDagang: json['merek_dagang']?.toString(),
      jenisKendaraan: json['jenis_kendaraan'] ?? '-',
      jenisPengajuan: json['jenis_pengajuan'] ?? 'Varian',
      nomorSut: json['nomor_sut']?.toString(),
      statusTdp:
          (json['is_tdp_outdated'] == true ||
              json['status_tdp'] == 'Diperbarui Admin')
          ? 'Diperbarui Admin'
          : (json['status_tdp'] ?? (hasDocCustomer ? 'Tanpa TDP' : '-')),
      documentCustomerId: docId,
      hasDocumentCustomer: hasDocCustomer,
      tdpMasaBerlaku: json['tdp_masa_berlaku'] != null
          ? '${json['tdp_masa_berlaku']}'
          : null,
      isTdpOutdated: json['is_tdp_outdated'] == true,
      hasKopSurat: json['has_kop_surat'] == false ? false : true,
      kopSource: json['kop_source'] ?? 'customer',
      fase: int.tryParse('${json['fase']}') ?? 1,
      fotoCopySkrb: json['foto_copy_skrb']?.toString(),
      tanggalPermohonan: json['tanggal_permohonan']?.toString(),
      suggestedFileName: json['suggested_file_name']?.toString(),
      customFiles: json['custom_files'] != null && json['custom_files'] is Map
          ? Map<String, dynamic>.from(json['custom_files'])
          : {},
      hiddenFlags: json['hidden_flags'] != null && json['hidden_flags'] is Map
          ? Map<String, dynamic>.from(json['hidden_flags'])
          : {},
      snapshotDocuments:
          json['snapshot_documents'] != null &&
              json['snapshot_documents'] is Map
          ? Map<String, dynamic>.from(json['snapshot_documents'])
          : {},
      histories: histList,
      createdAt: json['created_at'] ?? '-',
      updatedAt: json['updated_at'] ?? '-',
      alreadyExists: json['already_exists'] == true,
    );
  }

  bool isFileUpdatedInCurrentPhase(String key) {
    if (fase == 2) return false;
    final isSystem = ['1', '2', '3', '4', 'a', 'b', 'c', 'd'].contains(key);
    if (isSystem) return true;
    final modKeys = snapshotDocuments['modified_keys'];
    if (modKeys is Map && modKeys[key] == true) return true;
    return false;
  }
}
