// File: lib/elements/home/screens/detail_skrb_screen.dart
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:master_gambar/data/models/skrb.dart';
import '../providers/skrb_providers.dart';
import '../repository/skrb_repository.dart';
import '../widgets/skrb/skrb_history_dialog.dart';
import '../widgets/detail_skrb/doc_item.dart';
import '../widgets/detail_skrb/detail_skrb_top_bar.dart';
import '../widgets/detail_skrb/detail_skrb_content.dart';

class DetailSkrbScreen extends ConsumerStatefulWidget {
  final int? skrbId;
  const DetailSkrbScreen({super.key, this.skrbId});

  static Future<bool> checkAndConfirmUnsavedChanges(
    BuildContext context,
    WidgetRef ref, {
    Future<void> Function()? onSave,
  }) async {
    final hasUnsaved = ref.read(skrbUnsavedChangesProvider);
    if (!hasUnsaved) return true;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 8),
            Text('Peringatan: Simpan File Terlebih Dahulu'),
          ],
        ),
        content: const Text(
          'Anda telah memilih atau mengirim file dokumen, tetapi belum menyimpannya (Merger PDF).\n\nApakah Anda ingin menyimpannya terlebih dahulu sebelum berpindah ke halaman lain?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            onPressed: () => Navigator.pop(ctx, 'batal'),
            child: const Text('Batal (Tidak Jadi)'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
            ),
            onPressed: () => Navigator.pop(ctx, 'buang'),
            child: const Text('Buang (Tanpa Simpan)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Simpan'),
            onPressed: () => Navigator.pop(ctx, 'simpan'),
          ),
        ],
      ),
    );

    if (action == 'batal' || action == null) {
      return false; // Batal (tidak jadi navigasi ke Screen lain)
    }

    if (action == 'simpan') {
      final saveCb = onSave ?? ref.read(skrbSaveCallbackProvider);
      if (saveCb != null) {
        await saveCb();
      }
    }
    ref.read(skrbUnsavedChangesProvider.notifier).state = false;
    return true; // Lanjut navigasi (karena sudah pilih simpan atau buang)
  }

  @override
  ConsumerState<DetailSkrbScreen> createState() => _DetailSkrbScreenState();
}

class _DetailSkrbScreenState extends ConsumerState<DetailSkrbScreen> {
  bool _isProcessing = false;
  String? _processingKey;

  bool _showPdfCard = false;
  bool _isLoadingPdf = false;
  String? _pdfCardTitle;
  final List<Uint8List> _pdfBytesList = [];
  String? _currentPreviewKey;
  bool _hasTriggeredBackgroundGambar = false;
  bool _hasAutoLoadedPreview = false;
  int? _lastLoadedSkrbId;

  @override
  void didUpdateWidget(covariant DetailSkrbScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skrbId != widget.skrbId) {
      _hasTriggeredBackgroundGambar = false;
      _hasAutoLoadedPreview = false;
      _lastLoadedSkrbId = null;
    }
  }

  void _checkAndTriggerBackgroundGambar(Skrb skrb) {
    if (_hasTriggeredBackgroundGambar) return;
    if (skrb.snapshotDocuments['gambar_status'] == 'pending') {
      _hasTriggeredBackgroundGambar = true;
      Future.microtask(() async {
        try {
          final repository = ref.read(skrbRepositoryProvider);
          await repository.generateGambarUtamaBackground(skrb.id);
          if (mounted) {
            ref.invalidate(skrbDetailProvider(widget.skrbId!));
            ref.invalidate(skrbListProvider);
          }
        } catch (e) {
          debugPrint('Gagal generate gambar background: $e');
          _hasTriggeredBackgroundGambar = false;
        }
      });
    } else if (skrb.snapshotDocuments['gambar_status'] == 'ready') {
      _hasTriggeredBackgroundGambar = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(skrbUnsavedChangesProvider.notifier).state = false;
    });
  }

  void _openInlinePdfPreview(List<Uint8List> bytesList, String title) {
    _pdfBytesList.clear();
    setState(() {
      _pdfBytesList.addAll(bytesList);
      _pdfCardTitle = title;
      _isLoadingPdf = false;
      _showPdfCard = true;
    });
  }

  void _closeInlinePdfPreview() {
    _pdfBytesList.clear();
    setState(() {
      _isLoadingPdf = false;
      _showPdfCard = false;
      _currentPreviewKey = null;
    });
  }

  Future<void> _silentRefreshPreviewNo1() async {
    if (widget.skrbId == null || !_showPdfCard || _currentPreviewKey != '1') {
      return;
    }
    try {
      final repo = ref.read(skrbRepositoryProvider);
      final url = repo.getPdfViewUrl(widget.skrbId!, '1');
      final bytes = await repo.getPdfBytes(url);
      if (mounted &&
          _showPdfCard &&
          _currentPreviewKey == '1' &&
          _pdfBytesList.isNotEmpty) {
        setState(() {
          _pdfBytesList[0] = bytes;
        });
      }
    } catch (e) {
      // Abaikan error pada silent refresh
    }
  }

  @override
  void dispose() {
    _pdfBytesList.clear();
    super.dispose();
  }

  String _displayKey(String k) {
    switch (k.toLowerCase()) {
      case 'a':
      case 'b':
      case 'c':
      case 'd':
        return '';
      default:
        return k.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skrbId != null) {
      ref.watch(skrbDetailProvider(widget.skrbId!)).whenData((skrb) {
        _checkAndTriggerBackgroundGambar(skrb);
        if (!_hasAutoLoadedPreview &&
            skrb.id > 0 &&
            _lastLoadedSkrbId != skrb.id) {
          _hasAutoLoadedPreview = true;
          _lastLoadedSkrbId = skrb.id;
          Future.microtask(() {
            if (mounted) {
              final docItems = DocItem.buildList(skrb);
              final itemNo1 = docItems.where((d) => d.key == '1').firstOrNull;
              if (itemNo1 != null) {
                _handlePreviewPdf(skrb, itemNo1);
              }
            }
          });
        }
      });
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !ref.watch(skrbUnsavedChangesProvider),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canProceed = await DetailSkrbScreen.checkAndConfirmUnsavedChanges(
          context,
          ref,
        );
        if (canProceed && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            DetailSkrbTopBar(
              skrbId: widget.skrbId,
              onMerge: (skrb) => _handleMerge(skrb, download: false),
              onClosePreview: _closeInlinePdfPreview,
            ),
            Expanded(
              child: widget.skrbId == null
                  ? Center(
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 48,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.manage_search_outlined,
                                size: 64,
                                color: colorScheme.primary.withAlpha(180),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Silahkan cari dan Pilih SKRB pada dropdown di atas atau klik ikon Detail SKRB pada tabel Permohonan SKRB',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : DetailSkrbContent(
                      skrbId: widget.skrbId!,
                      showPdfCard: _showPdfCard,
                      isLoadingPdf: _isLoadingPdf,
                      pdfCardTitle: _pdfCardTitle,
                      pdfBytesList: _pdfBytesList,
                      isProcessing: _isProcessing,
                      processingKey: _processingKey,
                      onClosePdfPreview: _closeInlinePdfPreview,
                      onToggleHide: (key, isHidden) async {
                        await ref
                            .read(skrbDetailProvider(widget.skrbId!))
                            .maybeWhen(
                              data: (skrb) =>
                                  _handleToggleHide(skrb, key, isHidden),
                              orElse: () async {},
                            );
                      },
                      onUploadFile: (key) async {
                        await ref
                            .read(skrbDetailProvider(widget.skrbId!))
                            .maybeWhen(
                              data: (skrb) => _handleUploadFile(skrb, key),
                              orElse: () async {},
                            );
                      },
                      onPreviewPdf: (item) async {
                        await ref
                            .read(skrbDetailProvider(widget.skrbId!))
                            .maybeWhen(
                              data: (skrb) => _handlePreviewPdf(skrb, item),
                              orElse: () async {},
                            );
                      },
                      onMerge: ({required bool download}) async {
                        await ref
                            .read(skrbDetailProvider(widget.skrbId!))
                            .maybeWhen(
                              data: (skrb) =>
                                  _handleMerge(skrb, download: download),
                              orElse: () async {},
                            );
                      },
                      onSwitchPhase: (targetPhase) async {
                        await ref
                            .read(skrbDetailProvider(widget.skrbId!))
                            .maybeWhen(
                              data: (skrb) =>
                                  _handleSwitchPhase(skrb, targetPhase),
                              orElse: () async {},
                            );
                      },
                      onResetFiles: () {
                        final skrbAsync = ref.read(
                          skrbDetailProvider(widget.skrbId!),
                        );
                        skrbAsync.maybeWhen(
                          data: (skrb) => _confirmResetFiles(skrb),
                          orElse: () {},
                        );
                      },
                      onShowHistory: (skrb) => _showHistoryDialog(skrb),
                      onLiveUpdate: _silentRefreshPreviewNo1,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUploadFile(Skrb skrb, String key) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final isOptionalGroup = ['5', '6', '7', '8', '9'].contains(key);
    final maxBytes = isOptionalGroup ? 500 * 1024 : 5 * 1024 * 1024;
    final maxLabel = isOptionalGroup ? '500 KB' : '5 MB';
    if (file.size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ukuran file melebihi batas maksimal ($maxLabel)!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingKey = key;
    });

    try {
      await ref.read(skrbRepositoryProvider).uploadFile(skrb.id, key, file);
      ref.read(skrbUnsavedChangesProvider.notifier).state = true;
      final _ = await ref.refresh(skrbDetailProvider(skrb.id).future);
      ref.invalidate(skrbListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingKey = null;
        });
      }
    }
  }

  Future<void> _handlePreviewPdf(Skrb skrb, DocItem item) async {
    _currentPreviewKey = item.key;
    _pdfBytesList.clear();

    final keyDisplay = _displayKey(item.key);
    final prefix = keyDisplay.isEmpty ? '' : '[$keyDisplay] ';
    final int totalFiles = item.multiCount ?? 1;

    setState(() {
      _isProcessing = true;
      _isLoadingPdf = true;
      _showPdfCard = true;
      _pdfCardTitle = 'Memuat $prefix${item.label}...';
    });

    try {
      final repo = ref.read(skrbRepositoryProvider);
      final List<Uint8List> downloadedBytes = [];

      for (int i = 0; i < totalFiles; i++) {
        final url = repo.getPdfViewUrl(skrb.id, item.key, index: i);
        final bytes = await repo.getPdfBytes(url);
        downloadedBytes.add(bytes);
      }

      if (mounted) {
        final title = totalFiles > 1
            ? 'Preview: $prefix${item.label} (Total $totalFiles File pada Customer ini)'
            : 'Preview Dokumen: $prefix${item.label}';
        _openInlinePdfPreview(downloadedBytes, title);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
          _showPdfCard = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleToggleHide(
    Skrb skrb,
    String key,
    bool currentlyHidden,
  ) async {
    setState(() {
      _isProcessing = true;
      _processingKey = 'hide_$key';
    });

    try {
      final newFlags = Map<String, dynamic>.from(skrb.hiddenFlags);
      if (currentlyHidden) {
        newFlags.remove(key); // unhide
      } else {
        newFlags[key] = true; // hide
      }

      await ref
          .read(skrbRepositoryProvider)
          .updateHiddenFlags(skrb.id, newFlags);
      ref.read(skrbUnsavedChangesProvider.notifier).state = true;
      final _ = await ref.refresh(skrbDetailProvider(skrb.id).future);
      ref.invalidate(skrbListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal merubah status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingKey = null;
        });
      }
    }
  }

  void _showLoadingDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMerge(Skrb skrb, {required bool download}) async {
    if (skrb.snapshotDocuments['gambar_status'] == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gambar Tampak Utama masih diproses di background. Harap tunggu sesaat hingga tanda loading selesai.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final isMaxHistory = skrb.histories.length >= 3;
    if (!download && isMaxHistory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Tidak dapat menyimpan: Riwayat dokumen SKRB sudah mencapai batas maksimal (3/3). Harap hapus minimal 1 riwayat terlebih dahulu melalui menu History SKRB.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!skrb.hasKopSurat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Peringatan: Kop Surat belum ada di Document Customer maupun di default lokal! PDF akan dibuat tanpa Kop Surat.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    setState(() => _isProcessing = true);
    _showLoadingDialog(
      'Harap tunggu sebentar...\nMemproses dan Sync Seluruh File Dokumen SKRB',
    );

    try {
      await ref
          .read(skrbRepositoryProvider)
          .mergeSkrb(
            skrb.id,
            download: download,
            suggestedFileName: skrb.suggestedFileName,
          );

      ref.read(skrbUnsavedChangesProvider.notifier).state = false;
      final _ = await ref.refresh(skrbDetailProvider(skrb.id).future);
      ref.invalidate(skrbListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              download
                  ? (isMaxHistory
                        ? '📥 PDF SKRB berhasil diunduh secara langsung (Tanpa disimpan karena riwayat sudah maksimal 3/3)!'
                        : 'PDF SKRB berhasil disatukan dan diunduh ke komputer Anda!')
                  : 'PDF SKRB berhasil disatukan dan disimpan di server!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyatukan dokumen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSwitchPhase(Skrb skrb, int targetPhase) async {
    setState(() => _isProcessing = true);
    if (targetPhase == 3) {
      _showLoadingDialog('Harap tunggu sebentar...\nMenyiapkan dokumen...');
    } else {
      _showLoadingDialog(
        'Harap tunggu sebentar...\nMemvalidasi status...', // dan kembali ke Fase 2
      );
    }

    try {
      await ref.read(skrbRepositoryProvider).updatePhase(skrb.id, targetPhase);
      ref.read(skrbUnsavedChangesProvider.notifier).state = false;
      final _ = await ref.refresh(skrbDetailProvider(skrb.id).future);
      ref.invalidate(skrbListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal merubah fase: $e')));
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmResetFiles(Skrb skrb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus & Reset File SKRB'), // (Kembali ke Fase 1)
        content: const Text(
          'Apakah Anda yakin ingin menghapus seluruh gambar yang tersimpan di storage dan riwayat merger untuk SKRB ini?\n\nID SKRB dan ID Transaksi TETAP DIPERTAHANKAN dan status akan kembali ke semula.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = true);
              _showLoadingDialog(
                'Harap tunggu sebentar...\nMereset seluruh file tersenyap & riwayat SKRB...',
              );
              try {
                await ref.read(skrbRepositoryProvider).resetFiles(skrb.id);
                ref.read(skrbUnsavedChangesProvider.notifier).state = false;
                final _ = await ref.refresh(skrbDetailProvider(skrb.id).future);
                ref.invalidate(skrbListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seluruh file tersimpan telah dihapus.', //, kembali ke Fase 1
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error reset: $e')));
                }
              } finally {
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  setState(() => _isProcessing = false);
                }
              }
            },
            child: const Text(
              'Ya, Reset seperti semula', // Fase 1
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(Skrb skrb) {
    showDialog(
      context: context,
      builder: (_) => SkrbHistoryDialog(skrb: skrb),
    );
  }
}
