// File: lib/elements/home/widgets/skrb/tambah_permohonan_skrb_dialog.dart
import 'dart:ui' show ImageFilter;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_gambar/data/models/option_item.dart';
import 'package:master_gambar/data/models/skrb.dart';
import 'package:master_gambar/elements/home/providers/transaksi_providers.dart';
import '../../providers/skrb_providers.dart';
import '../../repository/skrb_repository.dart';
import 'card_id_skrb_setting.dart';

class TambahPermohonanSkrbDialog extends ConsumerStatefulWidget {
  final String? initialTransaksiId;
  const TambahPermohonanSkrbDialog({super.key, this.initialTransaksiId});

  @override
  ConsumerState<TambahPermohonanSkrbDialog> createState() =>
      _TambahPermohonanSkrbDialogState();
}

class _TambahPermohonanSkrbDialogState
    extends ConsumerState<TambahPermohonanSkrbDialog> {
  // --- Cara 1: pilih dari dropdown ID DWG ---
  SkrbAvailableTransaction? _selectedTransaction;

  // --- Cara 2: isi 3 dropdown mandiri ---
  OptionItem? _selectedCustomer;
  OptionItem? _selectedMasterData;
  int? _selectedJenisPengajuanId;

  // Loading state global
  bool _isLoading = false;
  bool _initialTransactionSet = false;

  // Controller untuk reset DropdownSearch secara manual
  final Key _customerDropdownKey = const ValueKey('customer_dialog_dd');
  final Key _kendaraanDropdownKey = const ValueKey('kendaraan_dialog_dd');
  final Key _pengajuanDropdownKey = const ValueKey('pengajuan_dialog_dd');
  final Key _transaksiDropdownKey = const ValueKey('transaksi_dialog_dd');

  // --- Card 2: State Preview ID & Nomor Urut Manual ---
  final TextEditingController _nomorController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _previewIdSkrb;
  bool _loadingPreview = false;
  String? _previewError;
  int? _currentPreviewCustomerId;

  @override
  void dispose() {
    _nomorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Tombol aktif jika:
  /// - Cara 1: ada transaksi terpilih, ATAU
  /// - Cara 2: ketiga dropdown terisi
  bool get _canCreate {
    if (_selectedTransaction != null) {
      return true;
    }
    if (_selectedCustomer != null &&
        _selectedMasterData != null &&
        _selectedJenisPengajuanId != null) {
      return true;
    }
    return false;
  }

  bool get _isCara1 => _selectedTransaction != null;

  void _resetForm() {
    setState(() {
      _selectedTransaction = null;
      _selectedMasterData = null;
      _selectedJenisPengajuanId = null;
      _nomorController.clear();
      _updateCustomerAndLoadPreview(null);
    });
  }

  void _updateCustomerAndLoadPreview(OptionItem? customer) {
    if (customer == null) {
      _selectedCustomer = null;
      _previewIdSkrb = null;
      _previewError = null;
      _currentPreviewCustomerId = null;
    } else {
      _selectedCustomer = customer;
      final newId = customer.id as int;
      if (newId != _currentPreviewCustomerId) {
        _currentPreviewCustomerId = newId;
        _loadPreviewId(newId);
      }
    }
  }

  Future<void> _loadPreviewId(int customerId) async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final repo = ref.read(skrbRepositoryProvider);
      final result = await repo.getPreviewIdSkrb(customerId);
      if (mounted && _currentPreviewCustomerId == customerId) {
        setState(() {
          _previewIdSkrb = result['preview_id_skrb'] as String?;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted && _currentPreviewCustomerId == customerId) {
        setState(() {
          _previewError = e.toString();
          _loadingPreview = false;
        });
      }
    }
  }

  int? _parseNomor() {
    final raw = _nomorController.text.trim();
    if (raw.isEmpty) return null;
    final val = int.tryParse(raw);
    if (val == null || val < 1) return null;
    return val;
  }

  void _onTransaksiChanged(SkrbAvailableTransaction? item) {
    setState(() {
      _selectedTransaction = item;
      if (item != null) {
        if (item.customerId != null && item.customerName.isNotEmpty) {
          _updateCustomerAndLoadPreview(
            OptionItem(id: item.customerId!, name: item.customerName),
          );
        } else {
          _updateCustomerAndLoadPreview(null);
        }

        if (item.masterDataId != null) {
          _selectedMasterData = OptionItem(
            id: item.masterDataId!,
            name:
                '${item.typeEngine} / ${item.merk} / ${item.chassisDisplayName} / ${item.jenisKendaraan}',
          );
        } else {
          _selectedMasterData = null;
        }

        _selectedJenisPengajuanId = item.jenisPengajuanId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableAsync = ref.watch(availableTransactionsProvider);
    final jenisPengajuanAsync = ref.watch(jenisPengajuanOptionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tambah Permohonan SKRB Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            tooltip: 'Tutup',
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Card 1: Data Inti SKRB ---
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Keterangan petunjuk
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.25,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Anda dapat memilih referensi ID DWG / Transaksi untuk mengisi data secara otomatis, atau melengkapi 3 kolom data inti secara mandiri.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Opsi 1: Dropdown Helper TRANSAKSI (ID DWG / Customer) ──
                    const Text(
                      '1. Pilih dari Transaksi / ID DWG (Opsional - Auto Isi Data)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    availableAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text(
                        'Error memuat transaksi: $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      data: (list) {
                        if (widget.initialTransaksiId != null &&
                            !_initialTransactionSet &&
                            _selectedTransaction == null) {
                          _initialTransactionSet = true;
                          final found = list
                              .where((x) => x.id == widget.initialTransaksiId)
                              .firstOrNull;
                          if (found != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _selectedTransaction == null) {
                                _onTransaksiChanged(found);
                              }
                            });
                          }
                        }
                        return DropdownSearch<SkrbAvailableTransaction>(
                          key: _transaksiDropdownKey,
                          items: (String filter, _) {
                            final query = filter.trim().toLowerCase();
                            if (query.isEmpty) {
                              return list.take(30).toList();
                            }
                            return list.where((item) {
                              return item.id.toLowerCase().contains(query) ||
                                  item.customerName.toLowerCase().contains(
                                    query,
                                  ) ||
                                  item.merk.toLowerCase().contains(query) ||
                                  item.chassisDisplayName
                                      .toLowerCase()
                                      .contains(query);
                            }).toList();
                          },
                          itemAsString: (item) =>
                              '${item.id} - ${item.customerName} (${item.merk} ${item.chassisDisplayName})',
                          compareFn: (i1, i2) => i1.id == i2.id,
                          selectedItem: _selectedTransaction,
                          onChanged: _onTransaksiChanged,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Cari & pilih ID DWG / Customer...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: const TextFieldProps(
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Ketik untuk mencari ID DWG...',
                                hintStyle: TextStyle(fontSize: 12),
                                prefixIcon: Icon(Icons.search, size: 18),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            itemBuilder: (ctx, item, isSel, isDis) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? colorScheme.primaryContainer.withValues(
                                        alpha: 0.3,
                                      )
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.id,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.typeEngine} | ${item.merk} | ${item.chassisDisplayName} | ${item.jenisKendaraan}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Divider Opsi 2
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ATAU ISI KETIGA DROPDOWN DI BAWAH INI (MODE MANDIRI / TANPA ID DWG)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Opsi 2: Data Inti SKRB (Wajib) ──
                    const Text(
                      '2. Data Inti SKRB (Wajib)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Baris: Customer + Jenis Pengajuan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer (60% proporsi)
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer *',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownSearch<OptionItem>(
                                key: _customerDropdownKey,
                                items: (String filter, _) => ref.read(
                                  customerOptionsSearchProvider(filter).future,
                                ),
                                itemAsString: (item) => item.name,
                                compareFn: (i1, i2) => i1.id == i2.id,
                                selectedItem: _selectedCustomer,
                                onChanged: (item) {
                                  setState(() {
                                    _updateCustomerAndLoadPreview(item);
                                    _selectedTransaction = null;
                                  });
                                },
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Pilih Customer...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: const TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Cari Customer...',
                                      hintStyle: TextStyle(fontSize: 12),
                                      prefixIcon: Icon(Icons.search, size: 18),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  itemBuilder: (ctx, item, isSel, isDis) =>
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        height: 36,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSel
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Jenis Pengajuan (40% proporsi)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jenis Pengajuan *',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              jenisPengajuanAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text(
                                  'Error: $e',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                  ),
                                ),
                                data: (items) {
                                  final filteredItems = items.where((e) => e.id != 4).toList();
                                  final selectedItem = filteredItems
                                      .where(
                                        (e) =>
                                            e.id == _selectedJenisPengajuanId,
                                      )
                                      .firstOrNull;
                                  return DropdownSearch<OptionItem>(
                                    key: _pengajuanDropdownKey,
                                    items: (filter, _) => filteredItems,
                                    itemAsString: (item) => item.name,
                                    compareFn: (i1, i2) => i1.id == i2.id,
                                    selectedItem: selectedItem,
                                    onChanged: (item) {
                                      setState(() {
                                        _selectedJenisPengajuanId =
                                            item?.id as int?;
                                        _selectedTransaction = null;
                                      });
                                    },
                                    decoratorProps: DropDownDecoratorProps(
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: 'Pilih Jenis...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: false,
                                      fit: FlexFit.loose,
                                      constraints: const BoxConstraints(
                                        maxHeight: 220,
                                      ),
                                      itemBuilder: (ctx, item, isSel, isDis) =>
                                          Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSel
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pilih Kendaraan (Full width 900)
                    const Text(
                      'Pilih Kendaraan (Engine / Merk / Chassis) *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownSearch<OptionItem>(
                      key: _kendaraanDropdownKey,
                      items: (String filter, _) => ref.read(
                        transaksiMasterDataOptionsProvider(filter).future,
                      ),
                      itemAsString: (item) => item.name,
                      compareFn: (i1, i2) => i1.id == i2.id,
                      selectedItem: _selectedMasterData,
                      onChanged: (item) {
                        setState(() {
                          _selectedMasterData = item;
                          _selectedTransaction = null;
                        });
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Cari & pilih spesifikasi kendaraan...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Cari Engine / Merk / Chassis...',
                            hintStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                        itemBuilder: (ctx, item, isSel, isDis) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 36,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info badge Mode Mandiri
                    if (!_isCara1 && _canCreate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mode Mandiri aktif — Permohonan SKRB akan dibuat langsung tanpa tautan ID Transaksi (ID DWG = "-")',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // --- Card 2: Konfirmasi ID SKRB & Pengaturan Nomor Urut (Muncul Dinamis) ---
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 18),
                CardIdSkrbSetting(
                  isEditMode: false,
                  customerName: _selectedCustomer!.name,
                  isCara1: _isCara1,
                  loadingPreview: _loadingPreview,
                  previewError: _previewError,
                  previewIdSkrb: _previewIdSkrb,
                  nomorController: _nomorController,
                  focusNode: _focusNode,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Builder(
          builder: (ctx) {
            final isManualSet =
                _nomorController.text.trim().isNotEmpty &&
                _parseNomor() != null;
            return Row(
              children: [
                TextButton.icon(
                  onPressed: _isLoading ? null : () => _resetForm(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
                const Spacer(),
                if (isManualSet) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ubah nomor urut (${_nomorController.text.trim().padLeft(2, '0')})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    _isCara1 ? 'Buat Permohonan' : 'Buat Permohonan',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: _isCara1 ? Colors.teal : Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (!_canCreate || _isLoading)
                      ? null
                      : () => _handleCreateSkrb(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _handleCreateSkrb() async {
    int? nomorManual;
    if (_nomorController.text.trim().isNotEmpty) {
      nomorManual = _parseNomor();
      if (nomorManual == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Masukkan nomor urut manual yang valid (angka, minimal 1)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_isCara1) {
      await _executeCreateCara1(nomorUrutManual: nomorManual);
    } else {
      await _executeCreateCara2(nomorUrutManual: nomorManual);
    }
  }

  Future<void> _executeCreateCara1({int? nomorUrutManual}) async {
    if (_selectedTransaction == null) {
      return;
    }

    setState(() => _isLoading = true);
    _showLoadingDialog('Harap tunggu...\nMembuat Permohonan SKRB Baru');

    try {
      final repository = ref.read(skrbRepositoryProvider);
      final newSkrb = await repository.createSkrbViaCara1(
        _selectedTransaction!.id,
        nomorUrutManual: nomorUrutManual,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        Navigator.of(
          context,
        ).pop(newSkrb); // Tutup dialog & kirim hasil ke screen utama
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        final msg = e.toString();
        final isDuplicateId =
            msg.toLowerCase().contains('sudah digunakan') ||
            msg.toLowerCase().contains('duplicate') ||
            msg.toLowerCase().contains('unique') ||
            msg.toLowerCase().contains('sudah terdaftar') ||
            msg.toLowerCase().contains('unik');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicateId ? '⚠️ $msg' : 'Gagal membuat SKRB: $msg',
            ),
            backgroundColor: isDuplicateId
                ? Colors.orange.shade800
                : Colors.red,
            duration: Duration(seconds: isDuplicateId ? 5 : 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _executeCreateCara2({int? nomorUrutManual}) async {
    setState(() => _isLoading = true);
    _showLoadingDialog(
      'Harap tunggu...\nMembuat Permohonan SKRB (Tanpa ID DWG)',
    );

    try {
      final repository = ref.read(skrbRepositoryProvider);
      final newSkrb = await repository.createSkrbViaCara2(
        customerId: _selectedCustomer!.id as int,
        masterDataId: _selectedMasterData!.id as int,
        jenisPengajuanId: _selectedJenisPengajuanId!,
        nomorUrutManual: nomorUrutManual,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        Navigator.of(
          context,
        ).pop(newSkrb); // Tutup dialog & kirim hasil ke screen utama
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        final msg = e.toString();
        final isDuplicateId =
            msg.toLowerCase().contains('sudah digunakan') ||
            msg.toLowerCase().contains('duplicate') ||
            msg.toLowerCase().contains('unique') ||
            msg.toLowerCase().contains('sudah terdaftar') ||
            msg.toLowerCase().contains('unik');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicateId ? '⚠️ $msg' : 'Gagal membuat SKRB: $msg',
            ),
            backgroundColor: isDuplicateId
                ? Colors.orange.shade800
                : Colors.red,
            duration: Duration(seconds: isDuplicateId ? 5 : 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
}
