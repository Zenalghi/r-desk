// File: lib/admin/master/widgets/gambar_utama_viewer_dialog.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/admin/master/models/g_gambar_utama.dart';
import 'package:master_gambar/admin/master/repository/master_data_repository.dart';
import 'package:pdfrx/pdfrx.dart';

class GambarUtamaViewerDialog extends ConsumerStatefulWidget {
  final GGambarUtama gambarUtama;

  const GambarUtamaViewerDialog({super.key, required this.gambarUtama});

  @override
  ConsumerState<GambarUtamaViewerDialog> createState() =>
      _GambarUtamaViewerDialogState();
}

class _GambarUtamaViewerDialogState
    extends ConsumerState<GambarUtamaViewerDialog>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  // bool _isLoadingPaths = true; // Tidak perlu loading lagi karena path sudah ada di object gambarUtama

  // List dinamis untuk Tab dan View
  List<Tab> _tabs = [];
  List<Widget> _views = [];

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  Future<void> _initTabs() async {
    try {
      // 1. Ambil Path lengkap dari Server (termasuk paket optional)
      final paths = await ref
          .read(masterDataRepositoryProvider)
          .getGambarUtamaPaths(widget.gambarUtama.id);

      List<Tab> tempTabs = [];
      List<Widget> tempViews = [];

      // 2. Helper function untuk tambah tab secara kondisional
      void addTabIfExist(String key, String label) {
        // Cek apakah key ada DAN value-nya tidak null/kosong
        if (paths.containsKey(key) &&
            paths[key] != null &&
            paths[key]!.isNotEmpty) {
          tempTabs.add(Tab(text: label));
          tempViews.add(_PdfLazyViewer(path: paths[key]));
        }
      }

      // 3. Tambahkan Tab sesuai ketersediaan data
      addTabIfExist('utama', 'Gambar Utama');
      addTabIfExist('terurai', 'Gambar Terurai');
      addTabIfExist('kontruksi', 'Gambar Kontruksi');
      addTabIfExist('paket', 'Gambar Paket');

      // 4. Jika tidak ada gambar sama sekali (Sangat jarang terjadi karena Utama wajib)
      if (tempTabs.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data gambar tidak ditemukan (file fisik hilang).'),
            ),
          );
        }
        return;
      }

      // 5. Update State
      if (mounted) {
        setState(() {
          _tabs = tempTabs;
          _views = tempViews;
          _tabController = TabController(length: _tabs.length, vsync: this);
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat path gambar: $e',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika controller belum siap
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      title: const Text('Pratinjau Gambar'),
      contentPadding: const EdgeInsets.fromLTRB(8.0, 1.0, 8.0, 8.0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // TabBar Dinamis
            TabBar(
              controller: _tabController,
              tabs: _tabs,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
            const SizedBox(height: 8),
            // View Dinamis
            Expanded(
              child: TabBarView(controller: _tabController, children: _views),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

// Widget Helper (TETAP SAMA)
class _PdfLazyViewer extends ConsumerStatefulWidget {
  final String? path;
  const _PdfLazyViewer({this.path});

  @override
  ConsumerState<_PdfLazyViewer> createState() => _PdfLazyViewerState();
}

class _PdfLazyViewerState extends ConsumerState<_PdfLazyViewer> {
  late final FutureProvider<Uint8List> _pdfDataProvider;
  final _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    // Unique key untuk provider agar tidak clash antar tab (opsional tapi aman)
    _pdfDataProvider = FutureProvider.autoDispose<Uint8List>((provRef) {
      if (widget.path == null) {
        throw Exception('Path PDF tidak ditemukan.');
      }
      return ref
          .read(masterDataRepositoryProvider)
          .getPdfFromPath(widget.path!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfDataAsync = ref.watch(_pdfDataProvider);

    return pdfDataAsync.when(
      data: (pdfData) => GestureDetector(
        onDoubleTapDown: (details) {
          if (_pdfController.isReady) {
            final current = _pdfController.currentZoom;
            final fit = _pdfController.alternativeFitScale ?? _pdfController.minScale;
            final cover = _pdfController.coverScale;
            if ((current - fit).abs() < 0.05) {
              _pdfController.setZoom(details.localPosition, cover);
            } else {
              _pdfController.setZoom(details.localPosition, fit);
            }
          }
        },
        onDoubleTap: () {},
        child: PdfViewer.data(
          pdfData,
          sourceName: widget.path ?? 'gambar_utama.pdf',
          controller: _pdfController,
          params: PdfViewerParams(
            textSelectionParams: const PdfTextSelectionParams(enabled: false),
            sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
              calculateInitialZoom: (doc, controller, altFitScale, coverScale) => altFitScale,
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Gagal memuat PDF: ${err.toString()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
