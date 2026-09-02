// File: lib/elements/home/widgets/detail_skrb/doc_item.dart
import 'package:master_gambar/data/models/skrb.dart';

class DocItem {
  final String key;
  final String label;
  final String? sublabel;
  final bool hasFile;
  final String statusText;
  final bool isOptionalUpload;
  final bool canBeHidden;
  final int? multiCount;
  final bool isBackgroundProcessing;

  const DocItem({
    required this.key,
    required this.label,
    this.sublabel,
    required this.hasFile,
    required this.statusText,
    required this.isOptionalUpload,
    required this.canBeHidden,
    this.multiCount,
    this.isBackgroundProcessing = false,
  });

  static List<DocItem> buildList(Skrb skrb) {
    final list = <DocItem>[];
    final snap = skrb.snapshotDocuments;

    String kopStatus;
    if (!skrb.hasKopSurat) {
      kopStatus = '⚠️ KOP BELUM ADA!\nHubungi Admin';
    } else {
      kopStatus = skrb.kopSource == 'customer'
          ? 'Kop Customer tersedia'
          : 'Template Ready (Kop Default Local)';
    }

    list.add(
      DocItem(
        key: '1',
        label: 'Surat Permohonan SKRB',
        sublabel: !skrb.hasKopSurat
            ? 'Peringatan: file Kop Surat tidak ditemukan!'
            : 'Otomatis dibuat sistem',
        hasFile: skrb.hasKopSurat,
        statusText: kopStatus,
        isOptionalUpload: false,
        canBeHidden: false,
      ),
    );

    // [KOMENTAR FITUR LAMA]: Sebelumnya sistem menambahkan baris terpisah untuk file Gambar Tampak Utama 1/2/3/4 (a, b, c, d).
    // Sesuai arahan baru, gambar utama tidak dimasukkan sebagai dokumen terpisah/proses background PDF di sini,
    // melainkan ditampilkan di dalam field dinamis (Smart Row) di bawah Surat Permohonan SKRB (No. 1).
    /*
    final gambarList = snap['gambar_utama_list'] ?? [];
    if (gambarList is List) {
      final numMap = {'a': '1', 'b': '2', 'c': '3', 'd': '4'};
      for (var item in gambarList) {
        if (item is Map) {
          final gKey = '${item['key'] ?? 'a'}';
          final gTitle = '${item['judul'] ?? 'Gambar Utama'}';
          final gVarian = '${item['varian'] ?? '-'}';
          final path = item['path'];
          final isCustom = skrb.customFiles.containsKey(gKey);
          final isPending = path == null && !isCustom && (item['status'] == 'pending' || snap['gambar_status'] == 'pending');
          final pageNum = numMap[gKey.toLowerCase()] ?? gKey;
          final pageLabel = 'Page $pageNum';
          list.add(
            DocItem(
              key: gKey,
              label: 'Gambar Tampak Utama $pageNum',
              sublabel: isPending ? '$gTitle - Varian: $gVarian (Proses Background...)' : '$gTitle - Varian: $gVarian',
              hasFile: path != null || isCustom,
              statusText: isPending
                  ? 'Sedang Memproses\n(Background Task)'
                  : isCustom
                  ? 'File diganti (Custom Upload)'
                  : 'Data dari Transaksi ($pageLabel)',
              isOptionalUpload: !isPending,
              isBackgroundProcessing: isPending,
              // Klien: Icon hide hanya untuk grup file Optional (no. 5 - 9). Jika ingin aktifkan di sini, cukup hilangkan komentar:
              canBeHidden: false, // canBeHidden: true,
            ),
          );
        }
      }
    }
    */

    final hasDataUmum =
        (snap['data_umum_file'] ?? snap['data_umum']) != null &&
        '${snap['data_umum_file'] ?? snap['data_umum']}'.isNotEmpty &&
        '${snap['data_umum_file'] ?? snap['data_umum']}' != 'null';
    list.add(
      DocItem(
        key: '2',
        label: 'Data Umum Perusahaan',
        sublabel: 'Dokumen Legalitas Customer',
        hasFile: hasDataUmum,
        statusText: hasDataUmum ? 'Data Umum Tersedia' : 'Belum Ada File',
        isOptionalUpload: false,
        // Klien: Icon hide hanya untuk grup file Optional (no. 5 - 9). Jika ingin aktifkan di sini, cukup hilangkan komentar:
        canBeHidden: false, // canBeHidden: true,
      ),
    );

    int tdpCount = 0;
    final tdpData = snap['tdp_files'] ?? snap['tdp_list'];
    if (tdpData != null && tdpData is List) {
      tdpCount = tdpData.length;
    }

    final hasDocCustomer = skrb.hasDocumentCustomer ||
        skrb.documentCustomerId != null ||
        snap['document_customer_id'] != null ||
        snap['data_umum_file'] != null ||
        snap['kop_surat_file'] != null ||
        snap['alamat_permohonan'] != null ||
        skrb.statusTdp == 'Tanpa TDP';

    list.add(
      DocItem(
        key: '3',
        label: 'Tanda Daftar Perusahaan (TDP)',
        sublabel: tdpCount > 0
            ? 'Tersedia $tdpCount file dari Dokumen Customer'
            : (hasDocCustomer
                ? 'Dokumen Customer Ada (Tanpa TDP)'
                : 'Belum Ada File TDP'),
        hasFile: tdpCount > 0,
        statusText: tdpCount > 0
            ? '${skrb.statusTdp}\n$tdpCount File'
            : (hasDocCustomer ? 'Tanpa TDP' : 'Kosong'),
        isOptionalUpload: false,
        // Klien: Icon hide hanya untuk grup file Optional (no. 5 - 9). Jika ingin aktifkan di sini, cukup hilangkan komentar:
        canBeHidden: false, // canBeHidden: true,
        multiCount: tdpCount > 0 ? tdpCount : null,
      ),
    );

    final hasSut =
        (snap['sut_file'] ?? snap['sut_pdf_path']) != null &&
        '${snap['sut_file'] ?? snap['sut_pdf_path']}'.isNotEmpty &&
        '${snap['sut_file'] ?? snap['sut_pdf_path']}' != 'null';
    list.add(
      DocItem(
        key: '4',
        label: 'Sertifikat Uji Tipe (SUT)',
        sublabel: 'File PDF SUT dari Master Type Chassis',
        hasFile: hasSut,
        statusText: hasSut
            ? 'SUT Tersedia'
            : 'SUT Tidak Tersedia\nHubungi Admin',
        isOptionalUpload: false,
        // Klien: Icon hide hanya untuk grup file Optional (no. 5 - 9). Jika ingin aktifkan di sini, cukup hilangkan komentar:
        canBeHidden: false, // canBeHidden: true,
      ),
    );

    final optNames = {
      '5': 'Surat Pernyataan',
      '6': 'Surat Perhitungan',
      '7': 'Brosur Alat',
      '8': 'Surat Rekomendasi',
      '9': 'Lampiran SKRB',
    };
    optNames.forEach((key, label) {
      final hasCust =
          skrb.customFiles[key] != null &&
          '${skrb.customFiles[key]}'.isNotEmpty;
      list.add(
        DocItem(
          key: key,
          label: label,
          sublabel: 'Diunggah manual (Maks 500 KB)',
          hasFile: hasCust,
          statusText: hasCust
              ? 'File Terunggah (${_getFilenameOnly(skrb.customFiles[key])})'
              : 'Belum Diunggah',
          isOptionalUpload: true,
          canBeHidden: true,
        ),
      );
    });
    return list;
  }

  static String _getFilenameOnly(dynamic path) {
    if (path == null) return '';
    final p = '$path';
    return p.split('/').last.split('\\').last;
  }
}
