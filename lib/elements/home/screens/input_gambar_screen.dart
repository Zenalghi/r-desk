// File: lib/elements/home/screens/input_gambar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/data/models/transaksi.dart';
import 'package:master_gambar/elements/home/providers/input_gambar_providers.dart';
import 'package:master_gambar/elements/home/providers/page_state_provider.dart';
import 'package:master_gambar/elements/home/repository/proses_transaksi_repository.dart';
import 'package:master_gambar/elements/home/widgets/gambar/gambar_header_info.dart';
import 'package:master_gambar/elements/home/widgets/gambar/gambar_main_form.dart';
import 'package:master_gambar/admin/master/widgets/pdf_viewer_dialog.dart';
import '../../../app/core/notifiers/refresh_notifier.dart';

class InputGambarScreen extends ConsumerStatefulWidget {
  final Transaksi? transaksi;
  const InputGambarScreen({super.key, this.transaksi});

  @override
  ConsumerState<InputGambarScreen> createState() => _InputGambarScreenState();
}

class _InputGambarScreenState extends ConsumerState<InputGambarScreen> {
  late TextEditingController _deskripsiOptionalController;
  bool _hasSavedData = false; // Penanda apakah data sudah tersimpan di DB

  @override
  void initState() {
    super.initState();
    _deskripsiOptionalController = TextEditingController();

    Future.microtask(() {
      _initOrReloadData();
    });
  }

  @override
  void dispose() {
    _deskripsiOptionalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InputGambarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaksi?.id != widget.transaksi?.id ||
        oldWidget.transaksi?.detail != widget.transaksi?.detail) {
      Future.microtask(() {
        _initOrReloadData();
      });
    }
  }

  void _initOrReloadData() {
    _resetInputGambarState();

    if (widget.transaksi == null) {
      _hasSavedData = false;
      ref.read(isEditModeProvider.notifier).state = false;
      return;
    }
    final trx = widget.transaksi!;

    // Cek apakah ada data detail yang tersimpan
    if (trx.detail != null) {
      _hasSavedData = true;
      // Jika ada data tersimpan, defaultnya adalah READ ONLY (Edit Mode = False)
      ref.read(isEditModeProvider.notifier).state = false;
      _loadSavedState(trx.detail!);
    } else {
      _hasSavedData = false;
      // Jika data baru, defaultnya adalah EDITABLE (Edit Mode = True)
      ref.read(isEditModeProvider.notifier).state = true;
    }

    // ---  BATASI JUMLAH GAMBAR UNTUK VARIAN ---
    final jenisPengajuan = trx.fPengajuan.jenisPengajuan.toUpperCase();
    if (jenisPengajuan == 'VARIAN') {
      final currentJumlah = ref.read(jumlahGambarProvider);
      if (currentJumlah > 3) {
        ref.read(jumlahGambarProvider.notifier).state = 3;
      }
    }
    Future.microtask(() {
      ref
          .read(independentListNotifierProvider.notifier)
          .fetchByMasterData(trx.masterDataId);
    });

    _fetchKelistrikanInfo();
  }

  void _resetInputGambarState() {
    ref.read(isProcessingProvider.notifier).state = false;
    ref.read(pemeriksaIdProvider.notifier).state = null;
    ref.read(pihakPenyetujuanProvider.notifier).state = 'vendor';
    ref.read(jumlahGambarProvider.notifier).state = 1;
    ref.invalidate(gambarUtamaSelectionProvider);
    ref.read(deskripsiOptionalProvider.notifier).state = '';
    ref.read(descSpaceProvider.notifier).state = 0;
    _deskripsiOptionalController.text = '';
    ref.invalidate(varianBodyStatusOptionsProvider);
    ref.invalidate(dependentOptionalOptionsProvider);
    ref.read(kelistrikanInfoProvider.notifier).state = null;
    ref.read(selectedKelistrikanIdProvider.notifier).state = null;
  }

  void _loadSavedState(TransaksiDetail detail) {
    ref.read(pemeriksaIdProvider.notifier).state = detail.pemeriksaId;
    ref.read(pihakPenyetujuanProvider.notifier).state = detail.pihakPenyetujuan;

    int fallbackJumlah = (detail.jumlahGambar > 0)
        ? detail.jumlahGambar
        : detail.dataGambarUtama.length;

    // Pastikan minimal ada 1 gambar yang dimuat
    if (fallbackJumlah == 0) fallbackJumlah = 1;

    final jenisPengajuan = widget.transaksi!.fPengajuan.jenisPengajuan
        .toUpperCase();
    int jumlahLoad = fallbackJumlah;

    // Jika saved data isinya 4 tapi jenisnya VARIAN, paksa jadi 3
    if (jenisPengajuan == 'VARIAN' && jumlahLoad > 3) {
      jumlahLoad = 3;
    }

    ref.read(jumlahGambarProvider.notifier).state = jumlahLoad;
    ref.read(gambarUtamaSelectionProvider.notifier).resize(jumlahLoad);

    for (int i = 0; i < detail.dataGambarUtama.length; i++) {
      if (i >= jumlahLoad) break;

      final item = detail.dataGambarUtama[i];
      ref
          .read(gambarUtamaSelectionProvider.notifier)
          .updateSelection(
            i,
            judulId: item['judul_id'],
            varianBodyId: item['varian_id'],
          );
    }

    if (detail.orderedIndependentIds != null &&
        detail.orderedIndependentIds!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ref
              .read(independentListNotifierProvider.notifier)
              .applySavedOrder(detail.orderedIndependentIds!);
        }
      });
    }

    if (detail.deskripsiOptional != null) {
      ref.read(deskripsiOptionalProvider.notifier).state =
          detail.deskripsiOptional!;
      _deskripsiOptionalController.text = detail.deskripsiOptional!;
    }

    if (detail.descSpace != null) {
      ref.read(descSpaceProvider.notifier).state = detail.descSpace!;
    }
    if (detail.iGambarKelistrikanId != null) {
      ref.read(selectedKelistrikanIdProvider.notifier).state =
          detail.iGambarKelistrikanId;
    }
  }

  Future<void> _fetchKelistrikanInfo() async {
    ref.read(isLoadingKelistrikanProvider.notifier).state = true;
    if (widget.transaksi == null) return;
    try {
      final info = await ref
          .read(prosesTransaksiRepositoryProvider)
          .getKelistrikanByMasterData(widget.transaksi!.masterDataId);

      if (mounted) {
        ref.read(kelistrikanInfoProvider.notifier).state = info;
        if (info != null && info['status_code'] == 'ready') {
          ref.read(selectedKelistrikanIdProvider.notifier).state =
              info['selected_id'];
        }
      }
    } catch (e) {
      // Handle silent
    } finally {
      if (mounted) {
        ref.read(isLoadingKelistrikanProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handlePreview(BuildContext context, int pageNumber) async {
    ref.read(isProcessingProvider.notifier).state = true;
    try {
      final pemeriksaId = ref.read(pemeriksaIdProvider);
      final pihakPenyetujuan = ref.read(
        pihakPenyetujuanProvider,
      ); // <-- AMBIL PIHAK PENYETUJUAN
      final selections = ref.read(gambarUtamaSelectionProvider);
      final deskripsiOptional = ref.read(deskripsiOptionalProvider);
      final independentAsync = ref.read(independentListNotifierProvider);
      List<int> orderedIndependentIds = [];

      independentAsync.whenData((state) {
        orderedIndependentIds = state.activeItems
            .map((e) => e.id as int)
            .toList();
      });

      final kelistrikanInfo = ref.read(kelistrikanInfoProvider);
      final statusKelistrikan = kelistrikanInfo?['status_code'];
      final kelistrikanId = ref.read(selectedKelistrikanIdProvider);
      final bool isKelistrikanReady =
          statusKelistrikan == 'ready' && kelistrikanId != null;

      // --- PERBAIKAN VALIDASI PEMERIKSA ---
      // Hanya wajib jika pihak penyetujuan adalah vendor
      if (pihakPenyetujuan == 'vendor' && pemeriksaId == null) {
        _showSnackBar('Pilih pemeriksa terlebih dahulu.', Colors.orange);
        return;
      }

      // --- Validasi Row Lengkap (Judul Wajib Diisi) ---
      final hasIncompleteRow = selections.any(
        (s) => s.varianBodyId != null && s.judulId == null,
      );
      if (hasIncompleteRow) {
        _showSnackBar(
          'Mohon lengkapi "Judul Gambar" untuk Varian Body yang telah dipilih.',
          Colors.orange,
        );
        return;
      }

      final varianBodyIds = selections
          .where((s) => s.varianBodyId != null && s.judulId != null)
          .map((s) => s.varianBodyId!)
          .toList();

      final judulGambarIds = selections
          .where((s) => s.varianBodyId != null && s.judulId != null)
          .map((s) => s.judulId!)
          .toList();

      final bool hasVarianBody = varianBodyIds.isNotEmpty;

      if (!hasVarianBody && !isKelistrikanReady) {
        _showSnackBar(
          'Pilih setidaknya satu Varian Body ATAU pastikan Kelistrikan tersedia.',
          Colors.orange,
        );
        return;
      }

      final dependentOptionalIds = ref.read(activeDependentOptionalIdsProvider);

      final bool isEditMode = ref.read(isEditModeProvider);

      List<Map<String, dynamic>> dataGambarUtama = selections
          .where((s) => s.varianBodyId != null && s.judulId != null)
          .map((s) => {'judul_id': s.judulId, 'varian_id': s.varianBodyId})
          .toList();

      // Jika dalam Mode Edit atau detail belum tersimpan di DB, update draft ke DB sebelum preview
      if (isEditMode || !_hasSavedData) {
        await ref.read(prosesTransaksiRepositoryProvider).saveDraft(
              pihakPenyetujuan: pihakPenyetujuan,
              transaksiId: widget.transaksi!.id,
              pemeriksaId: pemeriksaId,
              jumlahGambar: ref.read(jumlahGambarProvider),
              dataGambarUtama: dataGambarUtama,
              orderedIndependentIds: orderedIndependentIds,
              deskripsiOptional: deskripsiOptional,
              descSpace: ref.read(descSpaceProvider),
              iGambarKelistrikanId: kelistrikanId,
            );
        if (mounted) {
          setState(() {
            _hasSavedData = true;
          });
        }
      }

      int finalPageNumber = pageNumber;
      if (!hasVarianBody) {
        final jumlahGambarUtama = ref.read(jumlahGambarProvider);
        final int skippedPages =
            (jumlahGambarUtama * 3) + dependentOptionalIds.length;
        finalPageNumber = pageNumber - skippedPages;
        if (finalPageNumber < 1) finalPageNumber = 1;
      }

      final pdfData = await ref
          .read(prosesTransaksiRepositoryProvider)
          .getPreviewPdf(
            pihakPenyetujuan: pihakPenyetujuan, // <-- KIRIM PIHAK PENYETUJUAN
            dataGambarUtama: dataGambarUtama,
            orderedIndependentIds: orderedIndependentIds,
            transaksiId: widget.transaksi!.id,
            pemeriksaId: pemeriksaId, // Sekarang boleh null
            varianBodyIds: varianBodyIds,
            judulGambarIds: judulGambarIds,
            hGambarOptionalIds: dependentOptionalIds,
            pageNumber: finalPageNumber,
            deskripsiOptional: deskripsiOptional,
            descSpace: ref.read(descSpaceProvider),
            iGambarKelistrikanId: kelistrikanId,
            isEditMode: ref.read(isEditModeProvider),
          );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => PdfViewerDialog(
            pdfData: pdfData,
            title: 'Preview Halaman $pageNumber',
          ),
        );
      }
    } catch (e) {
      if (context.mounted)
        _showSnackBar('Error Preview: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) ref.read(isProcessingProvider.notifier).state = false;
    }
  }

  Future<void> _handleProses(BuildContext context) async {
    ref.read(isProcessingProvider.notifier).state = true;
    try {
      final jenisPengajuan = widget.transaksi!.fPengajuan.jenisPengajuan
          .toUpperCase();
      final bool isGambarTU = jenisPengajuan == 'GAMBAR TU';
      final String extension = isGambarTU ? 'pdf' : 'zip';
      final pemeriksaId = ref.read(pemeriksaIdProvider);
      final pihakPenyetujuan = ref.read(
        pihakPenyetujuanProvider,
      ); // <-- AMBIL PIHAK PENYETUJUAN
      final selections = ref.read(gambarUtamaSelectionProvider);
      final deskripsiOptional = ref.read(deskripsiOptionalProvider);
      final kelistrikanId = ref.read(selectedKelistrikanIdProvider);

      final varianBodyIds = selections
          .where((s) => s.varianBodyId != null && s.judulId != null)
          .map((s) => s.varianBodyId!)
          .toList();

      final judulGambarIds = selections
          .where((s) => s.varianBodyId != null && s.judulId != null)
          .map((s) => s.judulId!)
          .toList();

      final dependentOptionalIds = ref.read(activeDependentOptionalIdsProvider);
      final independentAsync = ref.read(independentListNotifierProvider);
      List<int> orderedIndependentIds = [];

      independentAsync.whenData((state) {
        orderedIndependentIds = state.activeItems
            .map((e) => e.id as int)
            .toList();
      });
      final rawFileName =
          '${widget.transaksi!.user.name} (${widget.transaksi!.fPengajuan.jenisPengajuan}) '
          '${widget.transaksi!.customer.namaPt}_${widget.transaksi!.bMerk.merk} '
          '${widget.transaksi!.cTypeChassis.typeChassis} (${widget.transaksi!.dJenisKendaraan.jenisKendaraan}).$extension';

      final suggestedFileName = rawFileName
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      await ref
          .read(prosesTransaksiRepositoryProvider)
          .downloadProcessedPdfs(
            pihakPenyetujuan: pihakPenyetujuan, // <-- KIRIM PIHAK PENYETUJUAN
            transaksiId: widget.transaksi!.id,
            suggestedFileName: suggestedFileName,
            extension: extension,
            pemeriksaId: pemeriksaId, // HAPUS TANDA SERU (!), karna boleh null
            varianBodyIds: varianBodyIds,
            judulGambarIds: judulGambarIds,
            hGambarOptionalIds: dependentOptionalIds,
            iGambarKelistrikanId: kelistrikanId,
            orderedIndependentIds: orderedIndependentIds,
            deskripsiOptional: deskripsiOptional,
            descSpace: ref.read(descSpaceProvider),
          );

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unduhan Berhasil'),
            content: const Text(
              'File ZIP berhasil disimpan di perangkat Anda.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        ref.read(pageStateProvider.notifier).state = PageState(pageIndex: 0);
      }
    } catch (e) {
      if (context.mounted)
        _showSnackBar('Error Proses: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) ref.read(isProcessingProvider.notifier).state = false;
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final pemeriksaId = ref.read(pemeriksaIdProvider);
    final pihakPenyetujuan = ref.read(
      pihakPenyetujuanProvider,
    ); // <-- AMBIL PIHAK PENYETUJUAN

    // --- PERBAIKAN VALIDASI SIMPAN ---
    if (pihakPenyetujuan == 'vendor' && pemeriksaId == null) {
      _showSnackBar(
        'Pilih pemeriksa internal untuk menyimpan draft.',
        Colors.orange,
      );
      return;
    }

    final kelistrikanId = ref.read(selectedKelistrikanIdProvider);
    final selections = ref.read(gambarUtamaSelectionProvider);
    List<Map<String, dynamic>> dataGambarUtama = selections
        .map((s) => {'judul_id': s.judulId, 'varian_id': s.varianBodyId})
        .toList();
    final independentAsync = ref.read(independentListNotifierProvider);
    List<int> currentOrderedIds = [];
    independentAsync.whenData((state) {
      currentOrderedIds = state.activeItems.map((e) => e.id as int).toList();
    });

    try {
      await ref
          .read(prosesTransaksiRepositoryProvider)
          .saveDraft(
            pihakPenyetujuan: pihakPenyetujuan, // <-- KIRIM PIHAK PENYETUJUAN
            transaksiId: widget.transaksi!.id,
            pemeriksaId: pemeriksaId, // Sekarang boleh null
            jumlahGambar: ref.read(jumlahGambarProvider),
            dataGambarUtama: dataGambarUtama,
            orderedIndependentIds: currentOrderedIds,
            deskripsiOptional: ref.read(deskripsiOptionalProvider),
            descSpace: ref.read(descSpaceProvider),
            iGambarKelistrikanId: kelistrikanId,
          );

      if (mounted) {
        _showSnackBar('Draft berhasil disimpan!', Colors.green);
        setState(() {
          _hasSavedData = true;
        });
        ref.read(isEditModeProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal simpan: $e', Colors.red);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text(
          'Yakin ingin menghapus seluruh data transaksi ini? Data yang dihapus tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ref
            .read(prosesTransaksiRepositoryProvider)
            .deleteTransaksi(widget.transaksi!.id);

        if (mounted) {
          _showSnackBar('Data berhasil dihapus.', Colors.green);
          ref.read(pageStateProvider.notifier).state = PageState(pageIndex: 0);
        }
      } catch (e) {
        if (mounted) _showSnackBar('Gagal menghapus: $e', Colors.red);
      }
    }
  }

  void _toggleEditMode() {
    final isEditMode = ref.read(isEditModeProvider);
    if (isEditMode) {
      if (widget.transaksi != null && widget.transaksi!.detail != null) {
        _loadSavedState(widget.transaksi!.detail!);
      }
      ref.read(isEditModeProvider.notifier).state = false;
      _showSnackBar('Edit dibatalkan.', Colors.blue);
    } else {
      ref.read(isEditModeProvider.notifier).state = true;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 50, right: 50),
      ),
    );
  }

  Widget _buildAksiButton(BuildContext context) {
    final pemeriksaId = ref.watch(pemeriksaIdProvider);
    final pihakPenyetujuan = ref.watch(pihakPenyetujuanProvider);
    final selections = ref.watch(gambarUtamaSelectionProvider);
    final isEditMode = ref.watch(isEditModeProvider);
    final isLoading = ref.watch(isProcessingProvider);

    // --- LOGIKA VALIDASI BUTTON BARU ---
    final isCustomerPenyetuju = pihakPenyetujuan == 'customer';
    final bool areSelectionsValid =
        selections.isNotEmpty &&
        selections.every((s) => s.judulId != null && s.varianBodyId != null);

    // Valid jika customer, ATAU jika vendor maka pemeriksaId harus terisi
    final bool isPemeriksaValid = isCustomerPenyetuju || pemeriksaId != null;
    final bool isFormValid = isPemeriksaValid && areSelectionsValid;

    // CASE 1: Belum ada data tersimpan (New Data) -> [Simpan] [Proses]
    if (!_hasSavedData) {
      return Row(children: [Expanded(child: _btnSimpan(context))]);
    }

    // CASE 2: Ada data & Mode Edit Aktif -> [Batal Edit] [Hapus] [Simpan]
    if (isEditMode) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _toggleEditMode,
              child: const Text(
                'Batal Edit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _handleDelete(context),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _btnSimpan(context)),
        ],
      );
    }

    // CASE 3: Ada data & Read Only -> [Edit] [Hapus] [Proses]
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _toggleEditMode,
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _handleDelete(context),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _btnProses(context, isFormValid, isLoading)),
      ],
    );
  }

  // Helper Widget Buttons
  Widget _btnSimpan(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save),
      label: const Text('Simpan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () => _handleSave(context),
    );
  }

  Widget _btnProses(BuildContext context, bool isValid, bool isLoading) {
    return ElevatedButton.icon(
      icon: isLoading ? Container() : const Icon(Icons.arrow_forward),
      label: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text('Proses Gambar'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: isValid && !isLoading ? () => _handleProses(context) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(jumlahGambarProvider, (previous, next) {
      ref.read(gambarUtamaSelectionProvider.notifier).resize(next);
    });
    ref.listen(refreshNotifierProvider, (_, __) {
      _initOrReloadData();
    });

    final jumlahGambarUtama = ref.watch(jumlahGambarProvider);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          GambarHeaderInfo(transaksi: widget.transaksi),
          const SizedBox(height: 5),
          if (widget.transaksi == null)
            Expanded(
              child: Center(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.manage_search_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Silahkan cari dan pilih id transaksi pada dropdown diatas\natau klik icon detail transaksi pada tabel transaksi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.transaksi != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: GambarMainForm(
                  transaksi: widget.transaksi!,
                  onPreviewPressed: (pageNumber) =>
                      _handlePreview(context, pageNumber),
                  jumlahGambarUtama: jumlahGambarUtama,
                  deskripsiController: _deskripsiOptionalController,
                ),
              ),
            ),
            const SizedBox(height: 5),
            _buildAksiButton(context),
          ],
        ],
      ),
    );
  }
}
